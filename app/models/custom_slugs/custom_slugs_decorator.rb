# frozen_string_literal: true

module CustomSlugs
  # This module contains all overrides necessary for implementing custom slugs for works and collections.
  # @see app/models/custom_slugs/slug_README.md

  ## Ability overrides ##
  # needed for load_and_authorize_resource
  Hyrax::Ability.class_eval do
    def permissions_doc(id_or_slug)
      super CustomSlugs::Manipulations.cast_to_slug(id_or_slug)
    end
  end

  ## Blacklight Overrides ##
  ## Blacklight-iiif-search override 1.0.0 to cast slug to id
  BlacklightIiifSearch::SearchBehavior.class_eval do
    def object_relation_solr_params
      { iiif_config[:object_relation_field] => CustomSlugs::Manipulations.cast_to_identifier(id) }
    end
  end

  ## ActiveFedora overrides ##
  # find by slug first, then look by id
  module ActiveFedoraFinderDecorator
    def find(*args)
      results = CustomSlugs::SlugBehavior.exact_slug_match(args.first).first
      results = super(*args) if results.blank?
      results
    end
  end
  ActiveFedora::Base.singleton_class.send :prepend, CustomSlugs::ActiveFedoraFinderDecorator

  ActiveFedora::Persistence.class_eval do
    def delete(opts = {})
      return self if new_record?

      @destroyed = true

      id = self.id ## cache so it's still available after delete
      solr_delete = to_param || self.id
      # Clear out the ETag
      @ldp_source = build_ldp_resource(id)
      begin
        @ldp_source.delete
      rescue Ldp::NotFound
        raise ObjectNotFoundError, "Unable to find #{id} in the repository"
      end

      ## OVERRIDE change delete to to_param instead of ID
      ActiveFedora::SolrService.delete(solr_delete) if ActiveFedora.enable_solr_updates?
      self.class.eradicate(id) if opts[:eradicate]
      freeze
    end
  end

  ActiveFedora::Relation.class_eval do
    # Override ActiveFedora 12.1 to support slug lookup
    def find_each(conditions = {}, opts = {})
      cast = opts.delete(:cast)
      search_in_batches(conditions, opts.merge(fl: "#{ActiveFedora.id_field},fedora_id_ssi")) do |group|
        group.each do |hit|
          begin
            from_fedora = load_from_fedora(hit['fedora_id_ssi'], cast) if hit['fedora_id_ssi'].present?
            from_fedora = load_from_fedora(hit[ActiveFedora.id_field], cast) if from_fedora.blank?
            yield(from_fedora)
          rescue Ldp::Gone
            # rubocop:disable Metrics/LineLength
            ActiveFedora::Base.logger.error "Although #{hit[ActiveFedora.id_field]} was found in Solr, it doesn't seem to exist in Fedora. The index is out of synch."
            # rubocop:enable Metrics/LineLength
          end
        end
      end
    end
  end

  ActiveFedora::Aggregation::BaseExtension.class_eval do
    private

      def ordered_by_ids
        if id.present?
          # rubocop:disable Metrics/LineLength
          query = "{!join from=proxy_in_ssi to=fedora_id_ssi}ordered_targets_ssim:#{id} OR {!join from=proxy_in_ssi to=id}ordered_targets_ssim:#{id}"
          # rubocop:enable Metrics/LineLength
          rows = ActiveFedora::SolrService::MAX_ROWS
          ActiveFedora::SolrService.query(query, rows: rows).map { |x| x["id"] }
        else
          []
        end
      end
  end

  ## Hyrax overrides ##
  # admin set file count
  Hyrax::AdminSetService.class_eval do
    private

      def count_files(admin_sets)
        file_counts = Hash.new(0)
        admin_sets.each do |admin_set|
          # rubocop:disable Metrics/LineLength
          query = "{!join from=file_set_ids_ssim to=fedora_id_ssi}isPartOf_ssim:#{admin_set.id} OR {!join from=file_set_ids_ssim to=id}isPartOf_ssim:#{admin_set.id}"
          # rubocop:enable Metrics/LineLength
          file_results = ActiveFedora::SolrService.instance.conn.get(
            ActiveFedora::SolrService.select_path,
            params: { fq: [query, "has_model_ssim:FileSet"],
                      rows: 0 }
          )
          file_counts[admin_set.id] = file_results['response']['numFound']
        end
        file_counts
      end
  end

  # get file set ids for member presenter
  Hyrax::MemberPresenterFactory.class_eval do
    private

      def file_set_ids
        @file_set_ids ||= begin
          # rubocop:disable Metrics/LineLength
          fq_query = (@work.fedora_id.blank? ? "{!join from=ordered_targets_ssim to=id}id:\"#{id}/list_source\"" : "{!join from=ordered_targets_ssim to=id}id:\"#{@work.fedora_id}/list_source\"")
          # rubocop:enable Metrics/LineLength
          ActiveFedora::SolrService.query(
            "{!field f=has_model_ssim}FileSet",
            rows: 10_000,
            fl: ActiveFedora.id_field,
            fq: fq_query
          ).flat_map { |x| x.fetch(ActiveFedora.id_field, []) }
        end
      end
  end

  # override to return slugs or ids instead of only ids
  Hyrax::WorkShowPresenter.class_eval do
    private

      def authorized_item_ids
        @member_item_list_ids ||= begin
          items = ordered_ids
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          CustomSlugs::Manipulations.cast_to_slug_or_ids_for(items)
        end
        @member_item_list_ids
      end
  end

  # search filesets and works in one go
  Hyrax::MemberWithFilesSearchBuilder.class_eval do
    def include_contained_files(solr_parameters)
      solr_parameters[:fq] ||= []
      # rubocop:disable Metrics/LineLength
      solr_parameters[:fq] << "{!join from=file_set_ids_ssim to=fedora_id_ssi}{!join from=child_object_ids_ssim to=id}id:#{collection_id} OR {!join from=file_set_ids_ssim to=id}{!join from=child_object_ids_ssim to=id}id:#{collection_id}"
      # rubocop:enable Metrics/LineLength
    end

    # include filters into the query to only include the collection members
    def include_collection_ids(solr_parameters)
      solr_parameters[:fq] ||= []
      # rubocop:disable Metrics/LineLength
      solr_parameters[:fq] << "{!join from=#{from_field} to=fedora_id_ssi}id:#{collection_id} OR {!join from=#{from_field} to=id}id:#{collection_id}"
      # rubocop:enable Metrics/LineLength
    end
  end

  Hyrax::SolrDocument::OrderedMembers.class_eval do
    private

      def query_for_ordered_ids(limit: 10_000,
                                proxy_field: 'proxy_in_ssi',
                                target_field: 'ordered_targets_ssim')
        query = []
        query << "#{proxy_field}:#{fedora_id}" if fedora_id
        query << "#{proxy_field}:#{id}" if id
        query = query.join(' OR ')
        ActiveFedora::SolrService
          .query(query, rows: limit, fl: target_field)
          .flat_map { |x| x.fetch(target_field, nil) }
          .compact
      end
  end

  module HyraxCollectionsPermissionsServiceDecorator
    def source_ids_for_user(access:, ability:, source_type: nil, exclude_groups: [])
      scope = Hyrax::PermissionTemplateAccess.for_user(ability: ability,
                                                       access: access,
                                                       exclude_groups: exclude_groups)
                                             .joins(:permission_template)
      # Override to convert ids to slugs before filter query
      ids = CustomSlugs::Manipulations.cast_to_slug_or_ids_for(scope.pluck(Arel.sql('DISTINCT source_id')))
      return ids unless source_type
      filter_source(source_type: source_type, ids: ids)
    end
  end
  # rubocop:disable Metrics/LineLength
  Hyrax::Collections::PermissionsService.singleton_class.send(:prepend, CustomSlugs::HyraxCollectionsPermissionsServiceDecorator)
  # rubocop:enable Metrics/LineLength

  # This module overrides the ActiveRecord::Base find methods to handle
  # retrieval of either custom slugs or identifiers for Hydra::PCDM objects.
  module ActiveRecordFinderDecorator
    def coerce_find_by_arg_for_slug_behavior(arg)
      if arg.is_a?(Hash) && arg.key?(:source_id)
        arg[:source_id] = CustomSlugs::Manipulations.cast_to_identifier(arg.fetch(:source_id))
        return arg
      end
      CustomSlugs::Manipulations.cast_to_identifier(arg)
    end

    def find_by(arg, *args)
      super(coerce_find_by_arg_for_slug_behavior(arg), *args)
    end

    def find_by!(arg, *args)
      super(coerce_find_by_arg_for_slug_behavior(arg), *args)
    end

    def find_or_create_by(attributes, &block)
      super(coerce_find_by_arg_for_slug_behavior(attributes), &block)
    end

    def find_or_create_by!(attributes, &block)
      super(coerce_find_by_arg_for_slug_behavior(attributes), &block)
    end

    def create_or_create_by(attributes, &block)
      super(coerce_find_by_arg_for_slug_behavior(attributes), &block)
    end

    def create_or_find_by!(attributes, &block)
      super(coerce_find_by_arg_for_slug_behavior(attributes), &block)
    end

    def find_or_initialize_by(attributes, &block)
      super(coerce_find_by_arg_for_slug_behavior(attributes), &block)
    end

    def find_sole_by(arg, *args)
      super(coerce_find_by_arg_for_slug_behavior(arg), *args)
    end
  end
  Hyrax::PermissionTemplate.singleton_class.send(:prepend, CustomSlugs::ActiveRecordFinderDecorator)

  # search for subcollections using the fedora id
  Hyrax::CollectionMemberSearchBuilder.class_eval do
    def member_of_collection(solr_parameters)
      # this method can be called on either a solr response or a collection object.
      # - for a solr document without a fedora_id indexed, the id itself will be the fedora id.
      # - on a collection object, the id is always the fedora id.
      collection_id = if collection.try(:solr_document).present?
                        collection.solr_document['fedora_id_ssi'] || collection.id
                      else
                        collection.id
                      end
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection_id}"
    end
  end

  # override to find all collections with deposit rights including slugs
  Hyrax::Dashboard::CollectionsSearchBuilder.class_eval do
    def apply_collection_deposit_permissions(_permission_types, _ability = current_ability)
      collection_ids = CustomSlugs::Manipulations.cast_to_slug_or_ids_for(collection_ids_for_deposit)
      return [] if collection_ids.empty?
      ["{!terms f=id}#{collection_ids.join(',')}"]
    end
  end

  # override to find all collections with deposit rights including slugs
  Hyrax::CollectionSearchBuilder.class_eval do
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      collection_ids = CustomSlugs::Manipulations.cast_to_slug_or_ids_for(collection_ids_for_deposit)
      return super unless permission_types.include?("deposit")
      ["{!terms f=id}#{collection_ids.join(',')}"]
    end
  end

  # search for the collections a work belongs to, using slugs when available
  Hyrax::ParentCollectionSearchBuilder.class_eval do
    def include_item_ids(solr_parameters)
      ids_to_search = CustomSlugs::Manipulations.cast_to_slug_or_ids_for(item.member_of_collection_ids)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids_to_search)
    end
  end

  # Overrides id list to include slugs when available
  Hyrax::NestedCollectionsParentSearchBuilder.class_eval do
    def parent_collections_only(solr_parameters)
      ids_to_search = CustomSlugs::Manipulations.cast_to_slug_or_ids_for(child.member_of_collection_ids)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids_to_search)
    end
  end

  # override nesting index adapter methods to use appropriate id
  module NestedIndexOverrides
    def find_solr_document_by(id:)
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
      document = ActiveFedora::SolrService.query(query, rows: 1).first
      if document.nil?
        query = ActiveFedora::SolrQueryBuilder.construct_query([['fedora_id_ssi', id]])
        document = ActiveFedora::SolrService.query(query, rows: 1).first
      end
      document = ActiveFedora::Base.find(id).to_solr if document.nil?
      raise "Unable to find SolrDocument with ID=#{id}" if document.nil?
      document
    end

    def each_child_document_of(document:, extent:)
      raw_child_solr_documents_of(parent_document: document).each do |solr_document|
        fedora_id = solr_document.fetch('fedora_id_ssi', nil) || solr_document.fetch('id')
        child_document = coerce_solr_document_to_index_document(original_solr_document: solr_document, id: fedora_id)
        # during light reindexing, we want to reindex the child only if fields aren't already there
        yield(child_document) if full_reindex?(extent: extent) || child_document.pathnames.empty?
      end
    end
  end
  Hyrax::Adapters::NestingIndexAdapter.singleton_class.send(:prepend, CustomSlugs::NestedIndexOverrides)

  # use to_param rather than id
  Hyrax::Dashboard::NestedCollectionsSearchBuilder.class_eval do
    def limit_ids
      # exclude current collection from returned list
      limit_ids = [@collection.to_param]
      # cannot add a parent that is already a parent
      limit_ids += @nesting_attributes.parents if @nesting_attributes.parents && @nest_direction == :as_parent
      limit_ids
    end
  end

  # Override to use to_param instead of id as needed
  module NestedCollectionQueryServiceDecorator
    def query_solr(collection:, access:, scope:, limit_to_id:, nest_direction:)
      nesting_attributes = Hyrax::Collections::NestedCollectionQueryService::NestingAttributes.new(
        id: collection.to_param,
        scope: scope
      )
      query_builder = Hyrax::Dashboard::NestedCollectionsSearchBuilder.new(
        access: access,
        collection: collection,
        scope: scope,
        nesting_attributes: nesting_attributes,
        nest_direction: nest_direction
      )

      query_builder.where(id: limit_to_id) if limit_to_id
      query = clean_lucene_error(builder: query_builder)
      scope.repository.search(query)
    end

    def parent_and_child_can_nest?(parent:, child:, scope:)
      return false if parent == child # Short-circuit
      return false unless parent.collection_type_gid == child.collection_type_gid
      return false if available_parent_collections(child: child, scope: scope, limit_to_id: parent.to_param).none?
      return false if available_child_collections(parent: parent, scope: scope, limit_to_id: child.to_param).none?
      true
    end

    def child_nesting_depth(child:, scope:)
      return 1 if child.nil?
      # rubocop:disable Metrics/LineLength
      builder = Hyrax::SearchBuilder.new(scope).where("#{Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames}:/.*#{child.id}.*/")
      # rubocop:enable Metrics/LineLength
      builder.query[:sort] = "#{Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth} desc"
      builder.query[:rows] = 1
      query = clean_lucene_error(builder: builder)
      response = scope.repository.search(query).documents.first

      descendant_depth = response[Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth]
      child_depth = Hyrax::Collections::NestedCollectionQueryService::NestingAttributes.new(
        id: child.to_param,
        scope: scope
      ).depth
      nesting_depth = descendant_depth - child_depth + 1
      nesting_depth.positive? ? nesting_depth : 1
    end

    def clean_lucene_error(builder:)
      query = builder.query.to_hash
      query['q'].gsub!('{!lucene}', '') if query.key?('q') &&
                                           query['q']&.include?('{!lucene}')
      query
    end

    def parent_nesting_depth(parent:, scope:)
      return 1 if parent.nil?
      Hyrax::Collections::NestedCollectionQueryService::NestingAttributes.new(id: parent.to_param, scope: scope).depth
    end
  end
  # rubocop:disable Metrics/LineLength
  Hyrax::Collections::NestedCollectionQueryService.singleton_class.send(:prepend, CustomSlugs::NestedCollectionQueryServiceDecorator)
  # rubocop:enable Metrics/LineLength

  # Override Hyrax  CollectionForm to require :identifier and move it up in the UI
  Hyrax::Forms::CollectionForm.class_eval do
    def required_fields
      %i[title
         description
         identifier]
    end

    def secondary_terms
      %i[creator
         contributor
         keyword
         license
         publisher
         date_created
         subject
         language
         based_near
         related_url
         resource_type]
    end

    def primary_terms
      required_fields
    end
  end
end
