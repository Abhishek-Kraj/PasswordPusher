# frozen_string_literal: true

module Admin
  class IntegrationsController < ::AdminController
    def index
      @sso_enabled = User::SSO_ENABLED
      @scim_enabled = User::SCIM_ENABLED
      @sso_users_count = User.where(provider: "microsoft_graph").count
      @scim_users_count = User.where(provider: "azure_ad").count
      @local_users_count = User.where(provider: [nil, ""]).count
      @deactivated_users_count = User.where(active: false).count
    end
  end
end
