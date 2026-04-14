# frozen_string_literal: true

class AppSetting < ApplicationRecord
  has_encrypted :encrypted_value

  validates :key, presence: true, uniqueness: true

  def self.get(key, fallback: nil)
    record = find_by(key: key)
    return fallback if record.nil?

    val = record.secret? ? record.encrypted_value : record.value
    val.presence || fallback
  end

  def self.set(key, value, secret: false)
    record = find_or_initialize_by(key: key)
    record.secret = secret
    if secret
      record.encrypted_value = value
      record.value = nil
    else
      record.value = value
      record.encrypted_value = nil
    end
    record.save!
  end

  def self.enabled?(key, fallback: false)
    ActiveModel::Type::Boolean.new.cast(get(key, fallback: fallback))
  end

  # SSO helpers with env var fallback
  def self.sso_enabled?
    enabled?("sso_enabled", fallback: ENV.fetch("PWP__SSO__ENABLED", false))
  end

  def self.sso_client_id
    get("sso_azure_client_id", fallback: ENV.fetch("PWP__SSO__AZURE_CLIENT_ID", ""))
  end

  def self.sso_client_secret
    get("sso_azure_client_secret", fallback: ENV.fetch("PWP__SSO__AZURE_CLIENT_SECRET", ""))
  end

  def self.sso_tenant_id
    get("sso_azure_tenant_id", fallback: ENV.fetch("PWP__SSO__AZURE_TENANT_ID", "common"))
  end

  # SCIM helpers with env var fallback
  def self.scim_enabled?
    enabled?("scim_enabled", fallback: ENV.fetch("PWP__SCIM__ENABLED", false))
  end

  def self.scim_bearer_token
    get("scim_bearer_token", fallback: ENV.fetch("PWP__SCIM__BEARER_TOKEN", ""))
  end
end
