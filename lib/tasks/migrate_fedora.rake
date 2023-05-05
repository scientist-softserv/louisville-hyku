# frozen_string_literal: true

namespace :louisville do
  desc 'Migrate metadata from a simple file Fedora db to a postgres-backed Fedora db without reprocessing files'
  task migrate_fedora: [:environment] do
    MigrateFedora.migrate!
  end

  desc 'Run Bulkrax Relationships'
  task run_relationships: [:environment] do
    MigrateFedora.run_relationships!
  end
end
