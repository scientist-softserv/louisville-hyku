# frozen_string_literal: true

# Provides a default host for the current tenant
class HykuMailer < ActionMailer::Base
  def default_url_options
    { host: ENV.fetch('HYKU_ROOT_HOST', nil) }
  end

  private

    def host_for_tenant
      Account.find_by(tenant: Apartment::Tenant.current)&.cname || Account.admin_host
    end
end
