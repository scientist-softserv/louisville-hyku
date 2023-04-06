# frozen_string_literal: true

RSpec.describe AppIndexer do
  let(:parent_work) { create(:work) }
  let(:child_work1) { create(:work, is_child: true) }
  let(:child_work2) { create(:work, is_child: true) }
  let(:ancestor_ids) { [child_work1.slug || child_work1.id, child_work2.slug || child_work2.id] }

  describe '#generate_solr_document' do
    subject(:solr_document) { service.generate_solr_document }
    let(:service) { described_class.new(child_work1) }
    let(:account) { create(:account, cname: 'hyky-test.me') }

    before do
      allow(Apartment::Tenant).to receive(:switch!).with(account.tenant) do |&block|
        block&.call
      end

      Apartment::Tenant.switch!(account.tenant) do
        Site.update(account: account)
        parent_work
        child_work1
        child_work2
      end

      parent_work.ordered_members += [child_work1, child_work2]
      parent_work.save!
    end

  # PASSED
    xit "indexer has the account_cname" do
      expect(solr_document.fetch("account_cname_tesim")).to eq(account.cname)
    end

  # PASSED
    xit 'indexes child_work1 custom fields' do
      expect(solr_document['is_child_bsi']).to eq child_work1.is_child # PASSED
      expect(solr_document['title_ssi']).to eq child_work1.title.first # PASSED
      expect(solr_document['identifier_ssi']).to eq child_work1.identifier.first # PASSED
    end
    include_examples("indexes_custom_slugs")
  end

  describe '#all_decendent_file_sets' do

  before do
    parent_work.ordered_members += [child_work1, child_work2]
    parent_work.save!
  end

    # CURRENTLY WORKING ON
    it 'returns an array of all descendant file set ids' do
      # Create a parent work
      byebug
      parent_work = create(:work)
      # Create two child works and add them to the parent work
      child_work1 = create(:work, is_child: true)
      child_work2 = create(:work, in_works: [parent_work], is_child: true)
      # Create some file sets and add them to the child works
      file_set1 = create(:file_set)
      file_set2 = create(:file_set, in_works: [child_work1])

      # Call the all_decendent_file_sets method on the parent work
      result = all_decendent_file_sets(parent_work)

      # Expect the result to include the ids of the file sets
      expect(result).to include(file_set1.id, file_set2.id)
    end
  end

  describe '#ancestor_ids' do
    # PASSED
  xit 'returns an array of all ancestor work ids' do
      expect(ancestor_ids).to contain_exactly(child_work1.slug || child_work1.id, child_work2.slug || child_work2.id)
    end
  end

  describe '#to_param' do
    # PASSED
    xit 'returns the slug or the id of the work' do
      expect(child_work1.to_param).to eq(child_work1.slug || child_work1.id)
      expect(child_work2.to_param).to eq(child_work2.slug || child_work2.id)
    end
  end

end
