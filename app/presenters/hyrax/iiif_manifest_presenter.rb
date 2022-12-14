# frozen_string_literal: true

module Hyrax
  ##
  # This presenter wraps objects in the interface required by `IIIFManifiest`.
  # It will accept either a Work-like resource or a SolrDocument.
  #
  # @example with a work
  #
  #   monograph = Monograph.new
  #   presenter = IiifManifestPresenter.new(monograph)
  #   presenter.title # => []
  #
  #   monograph.title = ['Comet in Moominland']
  #   presenter.title # => ['Comet in Moominland']
  #
  # @see https://www.rubydoc.info/gems/iiif_manifest
  class IiifManifestPresenter < Draper::Decorator
    delegate_all

    def search_service
      url = Rails.application.routes.url_helpers.solr_document_iiif_search_url(id, host: hostname)
      Site.account.ssl_configured ? url.sub(/\Ahttp:/, 'https:') : url
    end

    ##
    # @!attribute [w] ability
    #   @return [Ability]
    # @!attribute [w] hostname
    #   @return [String]
    attr_writer :ability, :hostname

    class << self
      ##
      # @param [Hyrax::Resource, SolrDocument]
      def for(model)
        klass = model.file_set? ? DisplayImagePresenter : IiifManifestPresenter

        klass.new(model)
      end
    end

    ##
    # @return [#can?]
    def ability
      @ability ||= NullAbility.new
    end

    ##
    # @return [String]
    def description
      Array(super).first || ''
    end

    ##
    # @return [Boolean]
    def file_set?
      model.try(:file_set?) || Array(model[:has_model_ssim]).include?('FileSet')
    end

    ##
    # @return [Array<DisplayImagePresenter>]
    def file_set_presenters
      member_presenters.select(&:file_set?)
    end

    ##
    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @todo should this use the simple_form i18n keys?! maybe the manifest
    #   needs its own?
    #
    # @return [Array<Hash{String => String}>] array of metadata hashes
    def manifest_metadata
      metadata_fields.map do |field_name|
        {
          'label' => I18n.t("simple_form.labels.defaults.#{field_name}"),
          'value' => Array(self[field_name]).map { |value| scrub(value.to_s) }
        }
      end
    end

    ##
    # @return [String] the URL where the manifest can be found
    def manifest_url
      return '' if id.blank?

      protocol = Site.account.ssl_configured ? 'https' : 'http'
      Rails.application.routes.url_helpers.polymorphic_url([:manifest, model], host: hostname, protocol: protocol)
    end

    ##
    # @return [Array<#to_s>]
    def member_ids
      list_of_ids = Hyrax::SolrDocument::OrderedMembers.decorate(model).ordered_member_ids
      CustomSlugs::Manipulations.cast_to_slug_or_ids_for(list_of_ids)
    end

    ##
    # @note cache member presenters to avoid querying repeatedly; we expect this
    #   presenter to live only as long as the request.
    #
    # @note skips presenters for objects the current `@ability` cannot read.
    #   the default ability has all permissions.
    #
    # @return [Array<IiifManifestPresenter>]
    def member_presenters
      @member_presenters_cache ||= Factory.build_for(ids: member_ids, presenter_class: self.class).map do |presenter|
        next unless ability.can?(:read, presenter.model)

        presenter.hostname = hostname
        presenter.ability  = ability
        presenter
      end.compact
    end

    ##
    # @return [Array<Hash{String => String}>]
    def sequence_rendering
      Array(try(:rendering_ids)).map do |file_set_id|
        rendering = file_set_presenters.find { |p| p.id == file_set_id }
        next unless rendering

        { '@id' => Hyrax::Engine.routes.url_helpers.download_url(rendering.id, host: hostname),
          'format' => rendering.mime_type.presence || I18n.t("hyrax.manifest.unknown_mime_text"),
          'label' => I18n.t("hyrax.manifest.download_text") + (rendering.label || '') }
      end.flatten
    end

    ##
    # @return [Boolean]
    def work?
      object.try(:work?) || !file_set?
    end

    ##
    # @return [Array<IiifManifestPresenter>]
    def work_presenters
      member_presenters.select(&:work?)
    end

    ##
    # @note ideally, this value will be cheap to retrieve, and will reliably
    #   change any time the manifest JSON will change. the current implementation
    #   is more blunt than this, changing only when the work itself changes.
    #
    # @return [String] a string tag suitable for cache keys for this manifiest
    def version
      object.try(:modified_date)&.to_s || ''
    end

    ##
    # An Ability-like object that gives `true` for all `can?` requests
    class NullAbility
      ##
      # @return [Boolean] true
      def can?(*)
        true
      end
    end

    class Factory < PresenterFactory
      ##
      # @return [Array]
      def build
        ids.map do |id|
          solr_doc = load_docs.find { |doc| doc.id == id }
          next unless solr_doc

          if solr_doc.file_set?
            presenter_class.for(solr_doc)
          elsif Hyrax.config.curation_concerns.include?(solr_doc.hydra_model)
            # look up file set ids and loop through those
            file_set_docs = load_file_set_docs(solr_doc.file_set_ids)
            file_set_docs.map { |doc| presenter_class.for(doc) } if file_set_docs.length
          end
        end.flatten.compact
      end

      private

        ##
        # cache the docs in this method, rather than #build;
        # this can probably be pushed up to the parent class
        def load_docs
          @cached_docs ||= super
        end

        # still create the manifest if the parent work has images attached but the child works do not
        def load_file_set_docs(file_set_ids)
          return [] if file_set_ids.nil?

          query("{!terms f=id}#{file_set_ids.join(',')}", rows: 1000)
            .map { |res| ::SolrDocument.new(res) }
        end
    end

    ##
    # a Presenter for producing `IIIFManifest::DisplayImage` objects
    #
    class DisplayImagePresenter < Draper::Decorator
      delegate_all

      include Hyrax::DisplaysImage

      ##
      # @!attribute [w] ability
      #   @return [Ability]
      # @!attribute [w] hostname
      #   @return [String]
      attr_writer :ability, :hostname

      ##
      # Creates a display image only where #model is an image.
      #
      # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
      def display_image
        return nil unless model.image?
        return nil unless latest_file_id

        IIIFManifest::DisplayImage
          .new(display_image_url(hostname),
               format: image_format(alpha_channels),
               width: width,
               height: height,
               iiif_endpoint: iiif_endpoint(latest_file_id, base_url: hostname))
      end

      def hostname
        @hostname || 'localhost'
      end

      ##
      # @return [Boolean] false
      def work?
        false
      end
    end

    private

      def hostname
        @hostname || 'localhost'
      end

      def metadata_fields
        Hyrax.config.iiif_metadata_fields
      end

      def scrub(value)
        Loofah.fragment(value).scrub!(:whitewash).to_s
      end
  end
end
