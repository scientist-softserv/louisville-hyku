# frozen_string_literal: true

namespace :hyku do
  namespace :update do
    desc 'Make sure all works have a thumbnail'
    task set_parent_thumbnail: [:environment] do
      Account.find_each do |account|
        begin
          switch!(account.cname)
          puts "********************** switched to #{account.cname} **********************"
          Hyrax.config.curation_concerns.each do |cc|
            next if cc.count.zero?

            puts "********************** checking #{cc}s **********************"
            cc.find_each do |work|
              next if work.thumbnail

              work.representative = work.file_sets.first if work.representative_id.blank?
              work.thumbnail = work.file_sets.first if work.thumbnail_id.blank?
              pdf = work.file_sets.select { |f| f.label.match(/.pdf/) }.first
              work.update_attributes!(rendering_ids: [pdf.id]) if pdf.present?
              work.save
            end
            puts "********************** updated #{cc}s **********************"
          end
        rescue StandardError => e
          puts "********************** error: #{e} **********************"
          next
        end
      end
    end
  end
end
