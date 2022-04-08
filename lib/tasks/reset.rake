# frozen_string_literal: true

namespace :hyrax do
  namespace :reset do
    desc "Delete Bulkrax importers in addition the reset below"
    task :all => :works_and_collections do
      # sometimes re-running an existing importer causes issues
      # and you may need to create new ones or delete the existing ones
      Bulkrax::Importer.delete_all
    end

    desc 'Reset fedora / solr and corresponding database tables w/o clearing other active record tables like users'
    task works_and_collections: [:environment] do
      AccountElevator.switch!('single.tenant.default')
      confirm('You are about to delete all works and collections, this is not reversable!')
      require 'active_fedora/cleaner'
      ActiveFedora::Cleaner.clean!
      Hyrax::PermissionTemplateAccess.delete_all
      Hyrax::PermissionTemplate.delete_all
      Bulkrax::PendingRelationship if defined?(Bulkrax::PendingRelationship)
      Bulkrax::Entry.delete_all
      # TODO(alishaevn): troubleshoot the error below as a result of trying to delete the importer runs
      # ActiveRecord::InvalidForeignKey: PG::ForeignKeyViolation: ERROR: update or delete on table "bulkrax_importer_runs" violates foreign key constraint "fk_rails_c6af228061" on table "bulkrax_pending_relationships"
      Bulkrax::ImporterRun.delete_all
      Bulkrax::Status.delete_all
      # Remove sipity methods, everything but sipity roles
      Sipity::Workflow.delete_all
      Sipity::EntitySpecificResponsibility.delete_all
      Sipity::Comment.delete_all
      Sipity::Entity.delete_all
      Sipity::WorkflowRole.delete_all
      Sipity::WorkflowResponsibility.delete_all
      Sipity::Agent.delete_all
      Mailboxer::Receipt.destroy_all
      Mailboxer::Notification.delete_all
      Mailboxer::Conversation::OptOut.delete_all
      Mailboxer::Conversation.delete_all
      AccountElevator.switch!('single.tenant.default')
      # we need to wait till Fedora is done with its cleanup
      # otherwise creating the admin set will fail
      while AdminSet.exists?(AdminSet::DEFAULT_ID)
        puts 'waiting for delete to finish before reinitializing Fedora'
        sleep 20
      end

      Hyrax::CollectionType.find_or_create_default_collection_type
      Hyrax::CollectionType.find_or_create_admin_set_type
      AdminSet.find_or_create_default_admin_set_id

      collection_types = Hyrax::CollectionType.all
      collection_types.each do |c|
        next unless c.title =~ /^translation missing/
        oldtitle = c.title
        c.title = I18n.t(c.title.gsub("translation missing: en.", ''))
        c.save
        puts "#{oldtitle} changed to #{c.title}"
      end
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
