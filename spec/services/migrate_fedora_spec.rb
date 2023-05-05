# frozen_string_literal: true

RSpec.describe MigrateFedora, type: :service do
  subject(:migrate_fedora_service) { described_class }

  describe '#migrate!' do
    after do
      FileUtils.rm('tmp/migrate_fedora.log')
    end

    it 'creates a log file at tmp/migrate_fedora.log' do
      allow(Hyrax::CollectionType).to receive(:find_or_create_default_collection_type)
      allow(Hyrax::CollectionType).to receive(:find_or_create_admin_set_type)
      allow(AdminSet).to receive(:find_or_create_default_admin_set_id)

      expect(File.exist?('tmp/migrate_fedora.log')).to eq(false)

      migrate_fedora_service.migrate!

      expect(File.exist?('tmp/migrate_fedora.log')).to eq(true)
    end

    it 'creates the default collection types', clean: true do
      expect { migrate_fedora_service.migrate! }
        .to change(Hyrax::CollectionType, :count)
        .by(2)
    end

    it 'creates the default admin set', clean: true do
      expect { migrate_fedora_service.migrate! }
        .to change(AdminSet, :count)
        .by(1)
    end
  end
end
