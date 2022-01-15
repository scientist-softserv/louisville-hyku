namespace :hyrax do
  namespace :reset do
    desc 'Reset fedora / solr and corrisponding database tables w/o clearing other active record tables like users'
    task works_and_collections: [:environment] do
      AccountElevator.switch!('single.tenant.default')
      confirm('You are about to delete all works and collections, this is not reversable!')
      require 'active_fedora/cleaner'
      ActiveFedora::Cleaner.clean!
      Hyrax::PermissionTemplateAccess.delete_all
      Hyrax::PermissionTemplate.delete_all
      Bulkrax::Entry.delete_all
      AccountElevator.switch!('single.tenant.default')
      # we need to wait till Fedora is done with its cleanup
      # otherwise creating the admin set will fail
      while AdminSet.exists?(AdminSet::DEFAULT_ID)
        puts 'waiting for delete to finish before reinitializing Fedora'
        sleep 20
      end
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["hyrax:default_admin_set:create"].invoke
    end
    def confirm(action)
      # rubocop:disable Style/GuardClause
      if ENV['RESET_CONFIRMED'].blank?
        confirm_token = rand(36**6).to_s(36)
        STDOUT.puts "#{action} Enter '#{confirm_token}' to confirm:"
        input = STDIN.gets.chomp
        raise "Aborting. You entered #{input}" unless input == confirm_token
      end
      # rubocop:enable Style/GuardClause
    end
  end
end
