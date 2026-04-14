# frozen_string_literal: true

module Admin
  class IntegrationsController < ::AdminController
    def index
      load_stats
      @sso_enabled = AppSetting.sso_enabled?
      @scim_enabled = AppSetting.scim_enabled?
      @sso_tenant_id = AppSetting.sso_tenant_id
      @sso_client_id = AppSetting.sso_client_id
      @scim_bearer_token = AppSetting.scim_bearer_token
    end

    def update_sso
      AppSetting.set("sso_enabled", params[:sso_enabled] == "1" ? "true" : "false")
      AppSetting.set("sso_azure_tenant_id", params[:sso_azure_tenant_id])
      AppSetting.set("sso_azure_client_id", params[:sso_azure_client_id])
      if params[:sso_azure_client_secret].present?
        AppSetting.set("sso_azure_client_secret", params[:sso_azure_client_secret], secret: true)
      end
      redirect_to admin_integrations_path, notice: _("SSO configuration saved. Restart the application for changes to take effect.")
    end

    def update_scim
      AppSetting.set("scim_enabled", params[:scim_enabled] == "1" ? "true" : "false")
      if params[:scim_bearer_token].present?
        AppSetting.set("scim_bearer_token", params[:scim_bearer_token], secret: true)
      end
      redirect_to admin_integrations_path, notice: _("SCIM configuration saved. Restart the application for changes to take effect.")
    end

    def regenerate_scim_token
      new_token = SecureRandom.hex(32)
      AppSetting.set("scim_bearer_token", new_token, secret: true)
      redirect_to admin_integrations_path, notice: _("SCIM bearer token regenerated. Update the token in Azure Entra ID.")
    end

    private

    def load_stats
      @sso_users_count = User.where(provider: "microsoft_graph").count
      @scim_users_count = User.where(provider: "azure_ad").count
      @local_users_count = User.where(provider: [nil, ""]).count
      @deactivated_users_count = User.where(active: false).count
    end
  end
end
