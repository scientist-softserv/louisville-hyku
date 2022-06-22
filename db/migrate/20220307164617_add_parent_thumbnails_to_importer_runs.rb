class AddParentThumbnailsToImporterRuns < ActiveRecord::Migration[5.2]
  def change
    add_column :bulkrax_importer_runs, :processed_parent_thumbnails, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :processed_parent_thumbnails)
    add_column :bulkrax_importer_runs, :failed_parent_thumbnails, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :failed_parent_thumbnails)
  end
end
