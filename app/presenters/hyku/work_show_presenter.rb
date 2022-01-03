# frozen_string_literal: true

module Hyku
  class WorkShowPresenter < Hyrax::WorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter

    delegate :alternative_title, 
             :biography_of_contributor, 
             :building_date, 
             :city, 
             :code,
             :collection_information, 
             :condition, 
             :contributor_description,  
             :contributor_history, 
             :contributor_role, 
             :county,
             :creator_role, 
             :cultural_context, 
             :data_source, 
             :date_digital, 
             :decade, 
             :descriptor,  
             :digitization_specification,
             :cataloguing_note, 
             :exhibit_history,  
             :extent, 
             :format,
             :honoree, 
             :invoice_information, 
             :iqb, 
             :issue, 
             :language_script,  
             :location, 
             :location_of_contributor, 
             :location_of_honoree, 
             :material, 
             :measurement,
             :media_type, 
             :mesh, 
             :neighborhood, 
             :object_location, 
             :operating_area, 
             :ordering_information, 
             :ornamentation, 
             :people_represented, 
             :photo_comment, 
             :place_original, 
             :production, 
             :region, 
             :related_image, 
             :related_material_and_publication_history, 
             :resource_query, 
             :series, 
             :story, 
             :street, 
             :style, 
             :tab_heading, 
             :table_of_contents, 
             :technique, 
             :transcription_translation, 
             :type_of_honoree,  
             :volume, 
             to: :solr_document

    # assumes there can only be one doi
    def doi
      doi_regex = %r{10\.\d{4,9}\/[-._;()\/:A-Z0-9]+}i
      doi = extract_from_identifier(doi_regex)
      doi&.join
    end

    # unlike doi, there can be multiple isbns
    def isbns
      isbn_regex = /((?:ISBN[- ]*13|ISBN[- ]*10|)\s*97[89][ -]*\d{1,5}[ -]*\d{1,7}[ -]*\d{1,6}[ -]*\d)|
                    ((?:[0-9][-]*){9}[ -]*[xX])|(^(?:[0-9][-]*){10}$)/x
      isbns = extract_from_identifier(isbn_regex)
      isbns&.flatten&.compact
    end

    private

      def extract_from_identifier(rgx)
        if solr_document['identifier_tesim'].present?
          ref = solr_document['identifier_tesim'].map do |str|
            str.scan(rgx)
          end
        end
        ref
      end
  end
end
