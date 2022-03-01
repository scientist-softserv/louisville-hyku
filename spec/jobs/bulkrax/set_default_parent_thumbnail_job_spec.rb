# frozen_string_literal: true

module Bulkrax
  RSpec.describe SetDefaultParentThumbnailJob, type: :job do
    subject(:set_default_parent_thumbnail_job) { described_class.new }
    describe '#perform' do
      context 'with a parent work' do
        it 'sets a thumbnail on the parent if there is not one already' do
        end

        it 'exits the job if the parent already has a thumbnail attached' do
        end
      end
    end
  end
end
