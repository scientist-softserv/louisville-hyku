# frozen_string_literal: true

RSpec.describe MigrateFedora, type: :service do
  subject(:migrate_fedora_service) { described_class.new }

  after do
    FileUtils.rm('tmp/migrate_fedora.log')
  end

  describe '#migrate!' do
    before do
      allow(Hyrax::CollectionType).to receive(:find_or_create_default_collection_type)
      allow(Hyrax::CollectionType).to receive(:find_or_create_admin_set_type)
      allow(AdminSet).to receive(:find_or_create_default_admin_set_id)
    end

    it 'calls #create_default_collection_types' do
      expect(migrate_fedora_service).to receive(:create_default_collection_types)

      migrate_fedora_service.migrate!
    end

    it 'calls #create_default_admin_set' do
      expect(migrate_fedora_service).to receive(:create_default_admin_set)

      migrate_fedora_service.migrate!
    end

    it 'calls #migrate_works' do
      expect(migrate_fedora_service).to receive(:migrate_works)

      migrate_fedora_service.migrate!
    end

    it 'calls #migrate_collections' do
      expect(migrate_fedora_service).to receive(:migrate_collections)

      migrate_fedora_service.migrate!
    end

    it 'calls #restore_relationships' do
      expect(migrate_fedora_service).to receive(:restore_relationships)

      migrate_fedora_service.migrate!
    end

    it 'calls #handle_errors' do
      expect(migrate_fedora_service).to receive(:handle_errors)

      migrate_fedora_service.migrate!
    end
  end

  describe '#initialize' do
    it 'creates a log file at tmp/migrate_fedora.log' do
      allow(Hyrax::CollectionType).to receive(:find_or_create_default_collection_type)
      allow(Hyrax::CollectionType).to receive(:find_or_create_admin_set_type)
      allow(AdminSet).to receive(:find_or_create_default_admin_set_id)

      expect(File.exist?('tmp/migrate_fedora.log')).to eq(false)

      described_class.new

      expect(File.exist?('tmp/migrate_fedora.log')).to eq(true)
    end
  end

  describe '#create_default_collection_types' do
    it 'creates the default collection types', clean: true do
      expect { migrate_fedora_service.create_default_collection_types }
        .to change(Hyrax::CollectionType, :count)
        .by(2)
    end
  end

  describe '#create_default_admin_set' do
    it 'creates the default admin set', clean: true do
      expect { migrate_fedora_service.create_default_admin_set }
        .to change(AdminSet, :count)
        .by(1)
    end
  end
end
