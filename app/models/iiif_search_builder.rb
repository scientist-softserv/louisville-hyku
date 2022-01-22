# frozen_string_literal: true

# SearchBuilder for full-text searches with highlighting and snippets
class IiifSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += [:ocr_search_params]

  def show_works_or_works_that_contain_files(solr_parameters)
    return if blacklight_params[:q].blank?
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
    solr_parameters[:defType] = 'lucene'
  end

  # set params for ocr field searching
  def ocr_search_params(solr_parameters = {})
    solr_parameters[:facet] = false
    solr_parameters[:hl] = true
    solr_parameters[:qf] = blacklight_config.iiif_search[:full_text_field]
    solr_parameters[:'hl.fl'] = blacklight_config.iiif_search[:full_text_field]
    solr_parameters[:'hl.fragsize'] = 100
    solr_parameters[:'hl.snippets'] = 10
  end

  private

    # the {!lucene} gives us the OR syntax
    def new_query
      "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)}"
    end

    # the _query_ allows for another parser (aka dismax)
    def interal_query(query_value)
      "_query_:\"#{query_value}\""
    end

    # the {!dismax} causes the query to go against the query fields
    def dismax_query
      "{!dismax v=$user_query}"
    end

    # join from file id to work relationship solrized file_set_ids_ssim
    def join_for_works_from_files
      "{!join from=#{ActiveFedora.id_field} to=file_set_ids_ssim}#{dismax_query}"
    end
end
