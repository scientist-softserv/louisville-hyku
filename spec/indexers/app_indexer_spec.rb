# frozen_string_literal: true

RSpec.describe AppIndexer do
  let(:file_set1) { create(:file_set, id: '123') }
  let(:file_set2) { create(:file_set, id: '456') }
  let(:file_set3) { create(:file_set, id: '789') }

  let(:child_work1) do
    create(:work, is_child: true).tap do |work|
      work.members << file_set1
      work.save!
    end
  end

  let(:child_work2) do
    create(:work, is_child: true).tap do |work|
      work.members << file_set2
      work.save!
    end
  end

  let(:parent_work) do
    create(:work).tap do |work|
      work.members << file_set3
      work.members += [file_set1, file_set2]
      work.ordered_members += [child_work1, child_work2]
      work.save!
    end
  end

  let(:service) { described_class.new(parent_work.reload) }
  let(:child_work1_solr_document) { AppIndexer.new(child_work1.reload).generate_solr_document }
  let(:child_work2_solr_document) { AppIndexer.new(child_work2.reload).generate_solr_document }

  describe '#generate_solr_document' do
    subject(:solr_document) { service.generate_solr_document }

    let(:account) { create(:account, cname: 'hyky-test.me') }

    before do
      allow(Apartment::Tenant).to receive(:switch!).with(account.tenant) do |&block|
        block&.call
      end

      Apartment::Tenant.switch!(account.tenant) do
        Site.update(account: account)
        parent_work
        child_work1
      end
    end

    it "indexer has the account_cname" do
      expect(solr_document.fetch("account_cname_tesim")).to eq(account.cname)
    end

    it 'indexes the parent_work custom fields' do
      expect(solr_document.fetch('is_child_bsi')).to eq parent_work.is_child
      expect(solr_document.fetch('title_ssi')).to eq parent_work.title.first
      expect(solr_document.fetch('identifier_ssi')).to eq parent_work.identifier.first
      expected_array = [file_set1.to_param, file_set2.to_param, file_set3.to_param, child_work1.to_param, child_work2.to_param]
      expect(solr_document.fetch('file_set_ids_ssim')).to match_array(expected_array)
    end

    it 'indexes the childs custom fields' do
      expect(child_work1_solr_document.fetch('is_page_of_ssim')).to include(parent_work.to_param)
      expect(child_work1_solr_document.fetch('is_child_bsi')).to eq child_work1.is_child
      expected_array = [file_set1.to_param]
      expect(child_work1_solr_document.fetch('file_set_ids_ssim')).to match_array(expected_array)
    end

    describe '#descendent_member_ids_for' do
      it 'returns an array of all descendant file set ids' do
        expected_array = [file_set1.to_param, file_set2.to_param, file_set3.to_param, child_work1.to_param, child_work2.to_param]
        expect(service.descendent_member_ids_for(parent_work)).to match_array(expected_array)
      end
    end

    describe '#ancestor_ids' do
      it 'returns an array of all ancestor slugs/ids' do
        expected_array = [file_set1.to_param, file_set2.to_param, file_set3.to_param, child_work1.to_param, child_work2.to_param]
        expect(service.ancestor_ids(parent_work)).to match_array(expected_array)
      end
    end
    include_examples("indexes_custom_slugs")
  end
end
