# Generated via
#  `rails generate hyrax:work Text`
class Text < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  # Adds behaviors for hyrax-doi plugin.
  #include Hyrax::DOI::DOIBehavior

  self.indexer = TextIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # Shared Metadata

  property :alternative_title, predicate: ::RDF::Vocab::DC.alternative, multiple: true do |index|
    index.as :stored_searchable
  end

  property :collection_information, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_findingAid"), multiple: true

  property :contributor_role, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe/Contribution"), multiple: true

  property :creator_role, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe/Role"), multiple: true

  property :date_digital, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_ProvisionActivity"), multiple: false

  property :digitization_specification, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_DigitalCharacteristic"), multiple: false

  property :format, predicate: ::RDF::Vocab::DC.format, multiple: false

  property :location, predicate: ::RDF::Vocab::DC.spatial, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :media_type, predicate: ::RDF::Vocab::DC.MediaType, multiple: true do |index|
    index.as :stored_searchable
  end

  property :mesh, predicate: ::RDF::Vocab::DC.MESH, multiple: true do |index|
    index.as :stored_searchable
  end

  property :ordering_information, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#c_UsePolicy"), multiple: false

  property :people_represented, predicate: ::RDF::Vocab::FOAF.name, multiple: true do |index|
    index.as :stored_searchable
  end

  property :resource_query, predicate: ::RDF::URI.new("https://purl.org/vra/isRelatedTo"), multiple: true do |index|
    index.as :stored_searchable
  end


  # Text Metadata

  property :issue, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_hasSubseries"), multiple: false do |index|
    index.as :stored_searchable
  end

  property :searchable_text, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_supplement"), multiple: false do |index|
    index.as :stored_searchable
  end

  property :table_of_contents, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :stored_searchable
  end

  property :volume, predicate: ::RDF::URI.new("https://id.loc.gov/ontologies/bibframe.html#p_hasSeries"), multiple: false do |index|
    index.as :stored_searchable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
