# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication
  include User::TotpAuthentication

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

  attr_readonly :admin

  def admin?
    admin
  end
end
