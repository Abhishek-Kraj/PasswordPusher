# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication
  include User::TotpAuthentication

  if defined?(Scimitar) && Settings.respond_to?(:scim) && Settings.scim&.enabled
    include Scimitar::Resources::Mixin
  end

  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  # Email-based modules (:confirmable, :lockable, :recoverable) are added when
  # Settings.enable_user_account_emails is true (requires SMTP in config/settings.yml).
  devise_modules = [:database_authenticatable, :registerable, :rememberable, :validatable, :trackable, :timeoutable]
  devise_modules += [:confirmable, :lockable, :recoverable] if Settings.enable_user_account_emails
  if Settings.respond_to?(:sso) && Settings.sso&.enabled
    devise_modules += [:omniauthable]
  end
  devise(*devise_modules, omniauth_providers: Settings.respond_to?(:sso) && Settings.sso&.enabled ? [:microsoft_graph] : [])

  has_many :pushes, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def self.scim_resource_type
    Scimitar::Resources::User
  end

  def self.scim_attributes_map
    {
      id: :id,
      externalId: :external_id,
      userName: :email,
      name: {givenName: :given_name, familyName: :family_name},
      emails: [{match: "work", with: :email}],
      active: :active
    }
  end

  def self.scim_queryable_attributes
    {
      "userName" => {column: :email},
      "externalId" => {column: :external_id},
      "emails" => {column: :email},
      "emails.value" => {column: :email}
    }
  end

  def self.scim_timestamps_map
    {
      created: :created_at,
      lastModified: :updated_at
    }
  end

  def before_scim_create
    self.password = Devise.friendly_token[0, 20]
    self.provider = "azure_ad"
    skip_confirmation! if respond_to?(:skip_confirmation!)
  end

  attr_readonly :admin

  def admin?
    admin
  end

  def active_for_authentication?
    super && (active.nil? || active)
  end

  def inactive_message
    active == false ? :deactivated : super
  end
end
