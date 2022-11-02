# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`
class Image < ActiveFedora::Base # rubocop:disable Metrics/ClassLength
  include ::Hyrax::WorkBehavior
  include SetChildFlag
  include CustomSlugs::SlugBehavior

  property :extent,
           predicate: ::RDF::Vocab::DC.extent,
           multiple: true do |index|
    index.as :stored_searchable
  end

  # Shared Metadata

  property :alternative_title,
           predicate: ::RDF::Vocab::DC.alternative,
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

  property :decade,
           predicate: ::RDF::Vocab::DC.temporal,
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :digitization_specification,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_DigitalCharacteristic"),
           multiple: false do |index|
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
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_UsePolicy"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :people_represented,
           predicate: ::RDF::Vocab::FOAF.name,
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :resource_query,
           predicate: ::RDF::URI.new("https://purl.org/vra/isRelatedTo"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  # Image Metadata

  property :building_date,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_temporalCoverage"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :city,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#City"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :code,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_code"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :county,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#County"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :invoice_information,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_referencedBy"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :neighborhood,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#CitySection"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :operating_area,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_GeographicCoverage"),
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :photo_comment,
           predicate: ::RDF::Vocab::DC.abstract,
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :production,
           predicate: ::RDF::URI.new("https://s3.amazonaws.com/VRA/ontology.html#wasProduced"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :region,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#Region"),
           multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :related_image,
           predicate: ::RDF::Vocab::DC.hasVersion,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :series,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_hasSeries"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :story,
           predicate: ::RDF::URI.new("https://purl.org/vra/hasContext"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  property :street,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/madsrdf/v1.html#Address"),
           multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :mesh,
           predicate: ::RDF::Vocab::DC.MESH,
           multiple: true do |index|
    index.as :stored_searchable
  end

  property :tab_heading,
           predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_Sublocation"),
           multiple: false do |index|
    index.as :stored_searchable
  end

  # This must come after the properties because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ImageIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  self.human_readable_type = 'Image'
end
