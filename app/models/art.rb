# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Art`
class Art < ActiveFedora::Base # rubocop:disable Metrics/ClassLength
  include ::Hyrax::WorkBehavior
  include SetChildFlag
  include CustomSlugs::SlugBehavior

  self.indexer = ArtIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # Shared Metadata

  property :alternative_title,
           predicate: ::RDF::Vocab::DC.alternative,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :variant_title,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_VariantTitle"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :collection_information,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_findingAid"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :contributor_role,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe/Contribution"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :creator_role,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe/Role"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :date_digital,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_ProvisionActivity"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :digitization_specification,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_DigitalCharacteristic"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :extent,
           predicate: ::RDF::Vocab::DC.extent,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :format,
           predicate: ::RDF::Vocab::DC.format,
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :location,
           predicate: ::RDF::Vocab::DC.spatial,
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :media_type,
           predicate: ::RDF::Vocab::DC.MediaType,
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :ordering_information,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_UsageAndAccessPolicy"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :people_represented,
           predicate: ::RDF::Vocab::FOAF.name,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :resource_query,
           predicate: ::RDF::URI.new("https://purl.org/vra/isRelatedTo"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  # Art Metadata

  property :biography_of_contributor,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_credits"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :cataloguing_note,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_DescriptionConventions"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :condition,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#historyNote"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :contributor_description,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_Summary"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :contributor_history,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_historyOfWork"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :cultural_context,
           predicate: ::RDF::URI.new("https://purl.org/vra/culturalContext"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :data_source,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_references"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :exhibit_history,
           predicate: ::RDF::URI.new("https://purl.org/vra/exhibitedAt"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :honoree,
           predicate: ::RDF::URI.new("https://purl.org/vra/designedFor"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :honoree, predicate: ::RDF::URI.new("https://purl.org/vra/designedFor"), multiple: true do |index|
    index.as :stored_searchable
  end

  property :language_script,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_Notation"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :location_of_contributor,
           predicate: ::RDF::URI.new("https://purl.org/vra/placeOfCreation"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :location_of_honoree,
           predicate: ::RDF::URI.new("https://purl.org/vra/locationOf"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :material,
           predicate: ::RDF::URI.new("https://purl.org/vra/material"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :measurement,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_dimensions"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :object_location,
           predicate: ::RDF::URI.new("https://purl.org/vra/placeOfOwnership"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :ornamentation,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_illustrativeContent"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :place_original,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_originPlace"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :related_image,
           predicate: ::RDF::Vocab::DC.temporal,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :style,
           predicate: ::RDF::URI.new("https://purl.org/vra/hasStylePeriod"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :technique,
           predicate: ::RDF::URI.new("https://purl.org/vra/hasTechnique"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :transcription_translation,
           predicate: ::RDF::URI.new("https://schema.org/translationOfWork"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :type_of_honoree,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#hasAffiliation"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
