# Generated via
#  `rails generate hyrax:work Text`
module Hyrax
  # Generated form for Text
  class TextForm < Hyrax::Forms::WorkForm
    # Adds behaviors for hyrax-doi plugin.
    # include Hyrax::DOI::DOIFormBehavior
    include Hyrax::TextFormTerms
    self.model_class = ::Text

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
                    #:decade,
                    :resource_type,
                    :collection_information,
                    :digitization_specification,
                    :date_digital,
                    :media_type, 
                    :mesh,
                    :format, 
                    :ordering_information,
                    :resource_query
                  ]
                   
    self.terms += [
                    :people_represented,
                    :location,
                    :table_of_contents,
                    :volume,
                    :issue,
                    :searchable_text
                  ]

  end
end
