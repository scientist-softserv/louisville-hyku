# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Art`
module Hyrax
  # Generated form for Art
  class ArtForm < Hyrax::Forms::WorkForm
    include Hyrax::ArtFormTerms
    self.model_class = ::Art

    self.required_fields -= %i[
      creator
      keyword
      rights_statement
      title
    ]

    self.terms -= [
      :based_near
    ]

    self.required_fields += %i[
      identifier
      title
    ]

    self.terms += [
      :alternative_title,
      :creator_role,
      :contributor_role,
      :resource_type,
      :collection_information,
      :digitization_specification,
      :date_digital,
      :media_type,
      :format,
      :ordering_information,
      :resource_query
    ]

    self.terms += %i[
      people_represented
      biography_of_contributor
      cataloguing_note
      condition
      contributor_description
      contributor_history
      cultural_context
      data_source
      exhibit_history
      extent
      honoree
      language_script
      location_of_contributor
      location_of_honoree
      material
      measurement
      object_location
      ornamentation
      place_original
      related_image
      style
      technique
      transcription_translation
      type_of_honoree
    ]
  end
end
