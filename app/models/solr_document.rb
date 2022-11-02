# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior
  # Add attributes for DOIs for hyrax-doi plugin.
  include NewspaperWorks::Solr::Document
  include Hyrax::DOI::SolrDocument::DOIBehavior

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models.
  use_extension(Hydra::ContentNegotiation)

  include CustomSlugs::SlugSolrAttributes

  attribute :alternative_title, Solr::Array, solr_name('alternative_title')
  attribute :biography_of_contributor, Solr::Array, solr_name('biography_of_contributor')
  attribute :building_date, Solr::Array, solr_name('building_date')
  attribute :city, Solr::Array, solr_name('city')
  attribute :code, Solr::Array, solr_name('code')
  attribute :collection_information, Solr::Array, solr_name('collection_information')
  attribute :condition, Solr::Array, solr_name('condition')
  attribute :contributor_description, Solr::Array, solr_name('contributor_description')
  attribute :contributor_history, Solr::Array, solr_name('contributor_history')
  attribute :contributor_role, Solr::Array, solr_name('contributor_role')
  attribute :county, Solr::Array, solr_name('county')
  attribute :creator_role, Solr::Array, solr_name('creator_role')
  attribute :cultural_context, Solr::Array, solr_name('cultural_context')
  attribute :data_source, Solr::Array, solr_name('data_source')
  attribute :date_digital, Solr::Array, solr_name('date_digital')
  attribute :decade, Solr::Array, solr_name('decade')
  attribute :digitization_specification, Solr::Array, solr_name('digitization_specification')
  attribute :cataloguing_note, Solr::Array, solr_name('cataloguing_note')
  attribute :exhibit_history, Solr::Array, solr_name('exhibit_history')
  attribute :format, Solr::Array, solr_name('format')
  attribute :honoree, Solr::Array, solr_name('honoree')
  attribute :invoice_information, Solr::Array, solr_name('invoice_information')
  attribute :issue, Solr::Array, solr_name('issue')
  attribute :is_child, Solr::String, "is_child_bsi"
  attribute :language_script, Solr::Array, solr_name('language_script')
  attribute :location, Solr::Array, solr_name('location')
  attribute :location_of_contributor, Solr::Array, solr_name('location_of_contributor')
  attribute :location_of_honoree, Solr::Array, solr_name('location_of_honoree')
  attribute :material, Solr::Array, solr_name('material')
  attribute :measurement, Solr::Array, solr_name('measurement')
  attribute :media_type, Solr::Array, solr_name('media_type')
  attribute :mesh, Solr::Array, solr_name('mesh')
  attribute :neighborhood, Solr::Array, solr_name('neighborhood')
  attribute :object_location, Solr::Array, solr_name('object_location')
  attribute :operating_area, Solr::Array, solr_name('operating_area')
  attribute :ordering_information, Solr::Array, solr_name('ordering_information')
  attribute :ornamentation, Solr::Array, solr_name('ornamentation')
  attribute :people_represented, Solr::Array, solr_name('people_represented')
  attribute :photo_comment, Solr::Array, solr_name('photo_comment')
  attribute :place_original, Solr::Array, solr_name('place_original')
  attribute :production, Solr::Array, solr_name('production')
  attribute :region, Solr::Array, solr_name('region')
  attribute :related_image, Solr::Array, solr_name('related_image')
  attribute :resource_query, Solr::Array, solr_name('resource_query')
  attribute :rights_statement, Solr::Array, solr_name('rights_statement')
  attribute :searchable_text, Solr::String, solr_name('searchable_text')
  attribute :series, Solr::Array, solr_name('series')
  attribute :story, Solr::Array, solr_name('story')
  attribute :street, Solr::Array, solr_name('street')
  attribute :style, Solr::Array, solr_name('style')
  attribute :tab_heading, Solr::Array, solr_name('tab_heading')
  attribute :table_of_contents, Solr::Array, solr_name('table_of_contents')
  attribute :technique, Solr::Array, solr_name('technique')
  attribute :transcription_translation, Solr::Array, solr_name('transcription_translation')
  attribute :type_of_honoree, Solr::Array, solr_name('type_of_honoree')
  attribute :volume, Solr::Array, solr_name('volume')

  attribute :extent, Solr::Array, solr_name('extent')
  attribute :rendering_ids, Solr::Array, solr_name('hasFormat', :symbol)
  attribute :account_cname, Solr::Array, solr_name('account_cname')

  field_semantics.merge!(
    contributor: 'contributor_tesim',
    creator: 'creator_tesim',
    date: 'date_created_tesim',
    description: 'description_tesim',
    identifier: 'identifier_tesim',
    language: 'language_tesim',
    publisher: 'publisher_tesim',
    relation: 'nesting_collection__pathnames_ssim',
    rights: 'rights_statement_tesim',
    subject: 'subject_tesim',
    title: 'title_tesim',
    type: 'human_readable_type_tesim'
  )
end
