# frozen_string_literal: true

xml.item do
  title = index_presenter(document).label(document_show_link_field(document)) ||
          document.to_semantic_values&.[](:title)&.first
  xml.title(title)
  xml.link(polymorphic_url(url_for_document(document)))
  xml.author(document.to_semantic_values[:author].first) if document.to_semantic_values.key? :author
end
