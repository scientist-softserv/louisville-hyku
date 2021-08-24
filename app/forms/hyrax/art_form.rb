# Generated via
#  `rails generate hyrax:work Art`
module Hyrax
  # Generated form for Art
  class ArtForm < Hyrax::Forms::WorkForm
    include Hyrax::ArtFormTerms
    self.model_class = ::Art

    self.required_fields -= [
                              :creator,
                              :keyword,
                              :rights_statement,
                              :title
                            ]

    self.terms -= [
                    :based_near,
                    :license
                  ]

    self.required_fields += [
                             :identifier,
                             :title
                            ]
                  
    self.terms += [
                    :alternative_title,
                    :creator_role,
                    :contributor_role,
                    #:date_original,
                    :decade,
                    :resource_type,
                    #:artificial_collection,
                    :collection_information,
                    :digitization_specification,
                    :date_digital,
                    :media_type,
                    :format,
                    :ordering_information,
                    :resource_query
                  ]
                   
    self.terms += [
                    :people_represented,
                    :location,
                    :biography_of_contributor,
                    :cataloguing_note,
                    :condition,
                    :contributor_description,
                    :contributor_history,
                    :cultural_context,
                    :data_source,
                    :description_1990,
                    :descriptor,
                    :exhibit_history,
                    :honoree,
                    :inscription,
                    :iqb,
                    :language_script,
                    :location_of_contributor,
                    :location_of_honoree,
                    :material,
                    :measurement,
                    :object_location,
                    :ornamentation,
                    :place_original,
                    :related_material_and_publication_history,
                    :resource_repository,
                    :style,
                    :technique,
                    :theme,
                    :transcription_translation,
                    :translated_title,
                    :type_of_honoree,
                    :type_of_work
                  ]

  end
end
