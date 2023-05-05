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

    # rubocop:disable RSpec/SubjectStub
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
    # rubocop:enable RSpec/SubjectStub
  end

  describe '#initialize' do
    context 'logging' do
      it 'sets up a logger' do
        expect(migrate_fedora_service.logger).to be_a(Logger)
      end

      it 'creates a log file at tmp/migrate_fedora.log' do
        expect(File.exist?('tmp/migrate_fedora.log')).to eq(false)

        described_class.new

        expect(File.exist?('tmp/migrate_fedora.log')).to eq(true)
      end
    end

    it 'gets all Bulkrax::Importer IDs' do
      importer_ids = [499, 567, 999]
      importer_ids.each do |id|
        create(:bulkrax_importer_csv, id: id)
      end

      expect(migrate_fedora_service.importer_ids).to eq(importer_ids)
    end

    it 'sets up an empty errors hash' do
      expect(migrate_fedora_service.errors).to eq({})
    end

    it 'sets up an empty array for collection entry IDs' do
      expect(migrate_fedora_service.collection_entry_ids).to eq([])
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
