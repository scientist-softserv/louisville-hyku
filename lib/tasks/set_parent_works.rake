# frozen_string_literal: true

namespace :hyku do
  namespace :update do
    desc 'Make sure all parent work models have the correct attribute'
    task is_parent_attribute: [:environment] do
      Account.find_each do |account|
        begin
          switch!(account.cname)
          puts "********************** switched to #{account.cname} **********************"
          Hyrax.config.curation_concerns.each do |cc|
            puts "********************** checking #{cc}s **********************"
            next if cc.count.zero?

            cc.find_each do |item|
              next if item.child_works.blank?
              next if item.is_parent

              item.update(is_parent: true)
            end
          end
        rescue StandardError
          puts "********************** failed to update account #{account.cname} **********************"
          next
        end
      end
    end
  end
end
