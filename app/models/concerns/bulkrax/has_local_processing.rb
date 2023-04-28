# frozen_string_literal: true

module Bulkrax
  module HasLocalProcessing
    # This method is called during build_metadata
    # add any special processing here, for example to reset a metadata property
    # to add a custom property from outside of the import data
    def add_local
      return if record['file_set_ids_to_restore'].blank?

      self.parsed_metadata['file_set_ids_to_restore'] = record['file_set_ids_to_restore']
    end
  end
end
