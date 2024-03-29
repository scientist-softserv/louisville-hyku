# frozen_string_literal: true

class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller

  # These before_action filters apply the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  def self.title_field
    solr_name('title', :stored_sortable)
  end

  def self.identifier
    solr_name('identifier', :stored_sortable)
  end

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller

  configure_blacklight do |config|
    # configuration for Blacklight IIIF Content Search
    config.iiif_search = {
      full_text_field: 'all_text_tsimv',
      object_relation_field: 'is_page_of_ssim',
      supported_params: %w[q page],
      autocomplete_handler: 'iiif_suggest',
      suggester_name: 'iiifSuggester'
    }

    config.view.gallery.partials = %i[index_header index]
    # config.view.masonry.partials = [:index]
    # config.view.slideshow.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search[:form_solr_parameters]['facet.field'] ||= %w[member_of_collections_ssim county_sim city_sim neighborhood_sim street_sim region_sim location_sim resource_type_sim media_type_sim publisher_sim resource_query_sim]
    config.advanced_search[:form_solr_parameters]['f.member_of_collections_ssim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.county_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.city_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.neighborhood_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.street_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.region_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.location_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.resource_type_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.media_type_sim.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.resource_query_sim.facet.limit'] ||= -1

    config.search_builder_class = CustomSearchBuilder

    # rubocop:disable Style/HashSyntax
    # rubocop:disable Style/SymbolLiteral
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: HYKU_METADATA_RENDERING_ATTRIBUTES.keys.map { |attribute| "#{attribute}_tesim" }
                                            .join(' ') << " title_tesim description_tesim all_text_tsimv",
      :"hl" => true,
      :"hl.simple.pre" => "<span class='highlight'>",
      :"hl.simple.post" => "</span>",
      :"hl.snippets" => 30,
      :"hl.fragsize" => 100
    }
    # rubocop:enable Style/SymbolLiteral
    # rubocop:enable Style/HashSyntax
    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = Solrizer.solr_name("tag", :facetable)

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    # config.facet_fields = {}
    # config.add_facet_field solr_name("human_readable_type", :facetable), label: "Type", limit: 5
    # config.add_facet_field 'resource_type_tesim', label: "Object Type", limit: 5

    config.add_facet_field solr_name('member_of_collections', :symbol), limit: 5, label: 'Collections'
    config.add_facet_field solr_name("subject", :facetable), limit: 5
    config.add_facet_field solr_name("people_represented", :facetable), limit: 5
    config.add_facet_field solr_name("county", :facetable), limit: 5
    config.add_facet_field solr_name("city", :facetable), limit: 5
    config.add_facet_field solr_name("neighborhood", :facetable), limit: 5
    config.add_facet_field solr_name("street", :facetable), limit: 5
    config.add_facet_field solr_name("region", :facetable), limit: 5
    config.add_facet_field solr_name("location", :facetable), limit: 5
    config.add_facet_field solr_name("decade", :facetable), limit: 5
    config.add_facet_field solr_name("creator", :facetable), limit: 5
    config.add_facet_field solr_name("contributor", :facetable), limit: 5
    config.add_facet_field solr_name("style", :facetable), limit: 5
    config.add_facet_field solr_name("technique", :facetable), limit: 5
    config.add_facet_field solr_name("material", :facetable), limit: 5
    config.add_facet_field solr_name("resource_type", :facetable), limit: 5
    config.add_facet_field solr_name("media_type", :facetable), limit: 5
    config.add_facet_field solr_name("publisher", :facetable), limit: 5
    config.add_facet_field solr_name("resource_query", :facetable), limit: 5
    
    # config.add_facet_field solr_name("keyword", :facetable), limit: 5
    # config.add_facet_field 'location_tesim', label: "Location", limit: 5
    # config.add_facet_field solr_name("location", :facetable), limit: 5
    # config.add_facet_field solr_name("language", :facetable), limit: 5
    # config.add_facet_field solr_name("based_near_label", :facetable), limit: 5
    # config.add_facet_field solr_name("file_format", :facetable), limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("identifier", :stored_searchable), itemprop: 'identifier'
    # config.add_index_field solr_name("identifier", :stored_searchable), helper_method: :index_field_link, field_name: 'identifier'
    config.add_index_field solr_name("title", :stored_searchable), itemprop: 'name', if: false
    config.add_index_field solr_name("description", :stored_searchable), itemprop: 'description', helper_method: :iconify_auto_link
    config.add_index_field solr_name("searchable_text", :stored_searchable), itemprop: 'searchable_text', label: 'Searchable Text', helper_method: :iconify_auto_link
    # config.add_index_field solr_name("keyword", :stored_searchable), itemprop: 'keywords', link_to_search: solr_name("keyword", :facetable)
    config.add_index_field solr_name("date_created", :stored_searchable), itemprop: 'dateCreated'
    # config.add_index_field solr_name("subject", :stored_searchable), itemprop: 'subject', link_to_search: solr_name("subject", :facetable)
    # config.add_index_field solr_name("decade", :stored_searchable), itemprop: 'decade', link_to_search: solr_name("decade", :facetable)
    # config.add_index_field solr_name("creator", :stored_searchable), itemprop: 'creator', link_to_search: solr_name("creator", :facetable)
    # config.add_index_field solr_name("contributor", :stored_searchable), itemprop: 'contributor', link_to_search: solr_name("contributor", :facetable)
    # config.add_index_field solr_name("location", :stored_searchable), itemprop: 'location', link_to_search: solr_name("location", :facetable)
    # config.add_index_field solr_name("proxy_depositor", :symbol), label: "Depositor", helper_method: :link_to_profile
    # config.add_index_field solr_name("depositor"), label: "Owner", helper_method: :link_to_profile
    # config.add_index_field solr_name("publisher", :stored_searchable), itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    # config.add_index_field solr_name("publisher", :stored_searchable), itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    # config.add_index_field solr_name("based_near_label", :stored_searchable), itemprop: 'contentLocation', link_to_search: solr_name("based_near_label", :facetable)
    # config.add_index_field solr_name("date_uploaded", :stored_sortable, type: :date), itemprop: 'datePublished', helper_method: :human_readable_date
    # config.add_index_field solr_name("date_modified", :stored_sortable, type: :date), itemprop: 'dateModified', helper_method: :human_readable_date
    # config.add_index_field solr_name("rights_statement", :stored_searchable), helper_method: :rights_statement_links
    # config.add_index_field solr_name("license", :stored_searchable), helper_method: :license_links
    # config.add_index_field solr_name("resource_type", :stored_searchable), link_to_search: solr_name("resource_type", :facetable)
    # config.add_index_field solr_name("file_format", :stored_searchable), link_to_search: solr_name("file_format", :facetable)
    # config.add_index_field solr_name("media_type", :stored_searchable), itemprop: 'media_type', link_to_search: solr_name("media_type", :facetable)
    # config.add_index_field solr_name("embargo_release_date", :stored_sortable, type: :date), label: "Embargo release date", helper_method: :human_readable_date
    # config.add_index_field solr_name("lease_expiration_date", :stored_sortable, type: :date), label: "Lease expiration date", helper_method: :human_readable_date
    # config.add_index_field solr_name("language", :stored_searchable), itemprop: 'inLanguage', link_to_search: solr_name("language", :facetable)
    config.add_index_field 'all_text_tsimv', highlight: true, helper_method: :render_ocr_snippets
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("title", :stored_searchable)
    config.add_show_field solr_name("description", :stored_searchable)
    config.add_show_field solr_name("keyword", :stored_searchable)
    config.add_show_field solr_name("subject", :stored_searchable)
    config.add_show_field solr_name("creator", :stored_searchable)
    config.add_show_field solr_name("contributor", :stored_searchable)
    config.add_show_field solr_name("publisher", :stored_searchable)
    # config.add_show_field solr_name("based_near_label", :stored_searchable)
    config.add_show_field solr_name("language", :stored_searchable)
    config.add_show_field solr_name("date_uploaded", :stored_searchable)
    config.add_show_field solr_name("date_modified", :stored_searchable)
    config.add_show_field solr_name("date_created", :stored_searchable)
    config.add_show_field solr_name("rights_statement", :stored_searchable)
    config.add_show_field solr_name("license", :stored_searchable)
    config.add_show_field solr_name("resource_type", :stored_searchable)
    config.add_show_field solr_name("format", :stored_searchable)
    config.add_show_field solr_name("identifier", :stored_searchable)

    # Shared Custom Metadata
    config.add_show_field solr_name('alternative_title', :stored_searchable)
    config.add_show_field solr_name('contributor_role', :stored_searchable)
    config.add_show_field solr_name('creator_role', :stored_searchable)
    config.add_show_field solr_name('date_digital', :stored_searchable)
    config.add_show_field solr_name('digitization_specification', :stored_searchable)
    config.add_show_field solr_name('extent', :stored_searchable)
    config.add_show_field solr_name('location', :stored_searchable)
    config.add_show_field solr_name('media_type', :stored_searchable)
    config.add_show_field solr_name('mesh', :stored_searchable)
    config.add_show_field solr_name('ordering_information', :stored_searchable)
    config.add_show_field solr_name('collection_information', :stored_searchable)
    config.add_show_field solr_name('people_represented', :stored_searchable)
    config.add_show_field solr_name('resource_query', :stored_searchable)

    # Art Work type
    config.add_show_field solr_name('honoree', :stored_searchable)
    config.add_show_field solr_name('type_of_honoree', :stored_searchable)
    config.add_show_field solr_name('location_of_honoree', :stored_searchable)
    config.add_show_field solr_name('location_of_contributor', :stored_searchable)
    config.add_show_field solr_name('biography_of_contributor', :stored_searchable)
    config.add_show_field solr_name('contributor_history', :stored_searchable)
    config.add_show_field solr_name('contributor_description', :stored_searchable)
    config.add_show_field solr_name('transcription_translation', :stored_searchable)
    config.add_show_field solr_name('style', :stored_searchable)
    config.add_show_field solr_name('technique', :stored_searchable)
    config.add_show_field solr_name('material', :stored_searchable)
    config.add_show_field solr_name('measurement', :stored_searchable)
    config.add_show_field solr_name('cultural_context', :stored_searchable)
    config.add_show_field solr_name('language_script', :stored_searchable)
    config.add_show_field solr_name('place_original', :stored_searchable)
    config.add_show_field solr_name('ornamentation', :stored_searchable)
    config.add_show_field solr_name('exhibit_history', :stored_searchable)
    config.add_show_field solr_name('data_source', :stored_searchable)
    config.add_show_field solr_name('cataloguing_note', :stored_searchable)
    config.add_show_field solr_name('object_location', :stored_searchable)
    config.add_show_field solr_name('condition', :stored_searchable)

    # Image Work Type
    config.add_show_field solr_name('city', :stored_searchable)
    config.add_show_field solr_name('code', :stored_searchable)
    config.add_show_field solr_name('county', :stored_searchable)
    config.add_show_field solr_name('decade', :stored_searchable)
    config.add_show_field solr_name('invoice_information', :stored_searchable)
    config.add_show_field solr_name('neighborhood', :stored_searchable)
    config.add_show_field solr_name('operating_area', :stored_searchable)
    config.add_show_field solr_name('photo_comment', :stored_searchable)
    config.add_show_field solr_name('region', :stored_searchable)
    config.add_show_field solr_name('series', :stored_searchable)
    config.add_show_field solr_name('story', :stored_searchable)
    config.add_show_field solr_name('street', :stored_searchable)
    config.add_show_field solr_name('tab_heading', :stored_searchable)

    # Text Work type
    config.add_show_field solr_name('issue', :stored_searchable)
    config.add_show_field solr_name('stored_text', :stored_searchable)
    config.add_show_field solr_name('table_of_contents', :stored_searchable)
    config.add_show_field solr_name('volume', :stored_searchable)
    config.add_show_field solr_name('searchable_text', :stored_searchable)

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: true, advanced_parse: false) do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim title_tesim all_text_tsimv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      field.include_in_advanced_search = true
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { "spellcheck.dictionary": "contributor" }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      field.include_in_advanced_search = true
      field.solr_parameters = { "spellcheck.dictionary": "creator" }
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      field.include_in_advanced_search = true
      field.solr_parameters = {
        "spellcheck.dictionary": "title"
      }
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.include_in_advanced_search = true
      # field.label = "Abstract or Summary"
      field.solr_parameters = {
        "spellcheck.dictionary": "description"
      }
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      field.include_in_advanced_search = false
      field.include_in_simple_select = false
      field.label = "Repository"
      field.solr_parameters = {
        "spellcheck.dictionary": "publisher"
      }
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_query') do |field|
      field.include_in_advanced_search = false
      field.include_in_simple_select = false
      field.label = "Resource_Query"
      field.solr_parameters = {
        "spellcheck.dictionary": "resource_query"
      }
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      field.include_in_advanced_search = false
      field.label = "Date Original"
      field.solr_parameters = {
        "spellcheck.dictionary": "date_created"
      }
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      field.include_in_advanced_search = true
      field.solr_parameters = {
        "spellcheck.dictionary": "subject"
      }
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('people_represented') do |field|
      field.include_in_advanced_search = true
      field.label = "People"
      field.solr_parameters = {
        "spellcheck.dictionary": "people_represented"
      }
      solr_name = solr_name("people_represented", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('story') do |field|
      field.include_in_advanced_search = true
      field.label = "Story"
      field.solr_parameters = {
        "spellcheck.dictionary": "story"
      }
      solr_name = solr_name("story", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "language"
      }
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      field.include_in_advanced_search = false
      # field.include_in_simple_select = false
      field.label = "Object Type"
      field.solr_parameters = {
        "spellcheck.dictionary": "resource_type"
      }
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('media_type') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "media_type"
      }
      solr_name = solr_name("media_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "format"
      }
      solr_name = solr_name("format", :stored_searchable)
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "identifier"
      }
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    #     config.add_search_field('based_near_label') do |field|
    #       field.label = "Location"
    #       field.solr_parameters = {
    #         "spellcheck.dictionary": "based_near_label"
    #       }
    #       solr_name = solr_name("based_near_label", :stored_searchable)
    #       field.solr_local_parameters = {
    #         qf: solr_name,
    #         pf: solr_name
    #       }
    #     end

    config.add_search_field('keyword') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        "spellcheck.dictionary": "keyword"
      }
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("depositor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('extent') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("extent", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{title_field} desc", label: "title \u25BC"
    config.add_sort_field "#{title_field} asc", label: "title \u25B2"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"
    config.add_sort_field "#{identifier} asc", label: "item number"

    # OAI Config fields
    config.oai = {
      provider: {
        repository_name: ->(controller) { controller.send(:current_account)&.name.presence },
        # repository_url:  ->(controller) { controller.oai_catalog_url },
        record_prefix: ->(controller) { controller.send(:current_account).oai_prefix },
        admin_email:   ->(controller) { controller.send(:current_account).oai_admin_email },
        sample_id:     ->(controller) { controller.send(:current_account).oai_sample_identifier }
      },
      document: {
        limit: 100, # number of records returned with each request, default: 15
        set_fields: [ # ability to define ListSets, optional, default: nil
          { label: 'collection', solr_field: 'isPartOf_ssim' }
        ]
      }
    }

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.add_field_configuration_to_solr_request!
  end

  # This is overridden just to give us a JSON response for debugging.
  def show
    _, @document = fetch params[:id]
    render json: @document.to_h
  end

  def iiif_search
    _parent_response, @parent_document = fetch(params[:solr_document_id])
    iiif_search = BlacklightIiifSearch::IiifSearch.new(iiif_search_params, iiif_search_config,
                                                       @parent_document)
    @response, _document_list = search_results(iiif_search.solr_params)
    iiif_search_response = BlacklightIiifSearch::IiifSearchResponse.new(@response,
                                                                        @parent_document,
                                                                        self)
    json_results = iiif_search_response.annotation_list
    json_results&.[]('resources')&.each do |result_hit|
      next if result_hit['resource'].present?
      result_hit['resource'] = {
        "@type": "cnt:ContentAsText",
        "chars": "Metadata match, see sidebar for details"
      }
    end

    render json: json_results,
           content_type: 'application/json'
  end
end
