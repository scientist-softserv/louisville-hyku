# frozen_string_literal: true

require 'rails_helper'

module Bulkrax
  RSpec.describe SetDefaultParentThumbnailJob, type: :job do
    subject(:set_default_parent_thumbnail_job) { described_class.new }

    let(:importer) { FactoryBot.create(:bulkrax_importer_csv) }
    let(:importer_run) { importer.last_run }
    let(:importer_run_id) { importer_run.id }
    let(:parent_work) { create(:text) }
    let(:parent_work_with_file) { create(:text) }
    let(:child_work_1) { build(:text, title: ['Child work 1'], identifier: ['Child_Work_1']) }
    let(:child_work_2) { build(:text, title: ['Child work 2'], identifier: ['Child_Work_2']) }
    let(:file_set_1) { build(:file_set, title: ['File set 1']) }
    let(:file_set_2) { build(:file_set, title: ['File set 2']) }
    let(:file_set_3) { build(:file_set, title: ['File set 3']) }

    before do
      allow(::Hyrax.config).to receive(:curation_concerns).and_return([GenericWork, Text, Art, Image])
      allow(Bulkrax::ImporterRun).to receive(:find).with(importer_run_id).and_return(importer_run)

      allow(child_work_1).to receive(:file_sets).and_return([file_set_1])
      allow(child_work_2).to receive(:file_sets).and_return([file_set_2])
      allow(parent_work).to receive(:child_works).and_return([child_work_1, child_work_2])

      allow(parent_work_with_file).to receive(:thumbnail).and_return(file_set_3)
      allow(parent_work_with_file).to receive(:child_works).and_return([child_work_1, child_work_2])
    end

    describe '#perform' do
      context 'with a parent work' do
        it 'sets a thumbnail on the parent if there is not one already' do
          expect(importer_run).to receive(:increment!).with(:processed_parent_thumbnails)

          set_default_parent_thumbnail_job.perform(
            parent_work: parent_work,
            importer_run_id: importer_run_id
          )

          expect(parent_work.thumbnail).to eq(file_set_1)
          expect(parent_work.thumbnail).not_to eq(file_set_2)
          expect(parent_work.thumbnail).not_to eq(file_set_3)
        end

        it 'exits the job if the parent already has a thumbnail attached' do
          set_default_parent_thumbnail_job.perform(
            parent_work: parent_work_with_file,
            importer_run_id: importer_run_id
          )

          expect(parent_work_with_file.thumbnail).to eq(file_set_3)
          expect(parent_work_with_file.thumbnail).not_to eq(file_set_1)
          expect(parent_work_with_file.thumbnail).not_to eq(file_set_2)
        end
      end

      context 'without a parent work' do
        it 'returns an error' do
          expect(importer_run).to receive(:increment!).with(:failed_parent_thumbnails)

          set_default_parent_thumbnail_job.perform(
            parent_work: nil,
            importer_run_id: importer_run_id
          )
        end
      end
    end
  end
end
