# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`
module Hyrax
  class ImageForm < Hyrax::Forms::WorkForm
    include Hyrax::ImageFormTerms
    self.model_class = ::Image

    self.required_fields -= [
                              :creator,
                              :keyword,
                              :rights_statement,
                              :title
                            ]

    self.terms -= [
                    :based_near
                  ]
                  
    self.required_fields += [
                             :identifier,
                             :title
                            ]
                            
    self.terms += [
                    :alternative_title,
                    :creator_role,
                    :contributor_role,
                    :decade,
                    :resource_type,
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
                    :street,
                    :neighborhood,
                    :city,
                    :code,
                    :county,
                    :building_date,
                    :extent,
                    :invoice_information,
                    :operating_area,
                    :photo_comment,
                    :production,
                    :region,
                    :related_image,
                    :series,
                    :story,
                    :mesh,
                    :tab_heading
                  ]

  end
end
