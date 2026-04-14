# frozen_string_literal: true

# Read SCIM enabled flag from AppSetting (DB) with env var fallback.
# AppSetting may not exist yet (before migration), so rescue gracefully.
_scim_enabled = begin
  AppSetting.scim_enabled?
rescue
  ActiveModel::Type::Boolean.new.cast(ENV.fetch("PWP__SCIM__ENABLED", false))
end

if defined?(Scimitar) && _scim_enabled
  Rails.application.config.to_prepare do
    Scimitar.engine_configuration = Scimitar::EngineConfiguration.new(
      token_authenticator: proc { |token, _options|
        expected = begin
          AppSetting.scim_bearer_token
        rescue
          ENV.fetch("PWP__SCIM__BEARER_TOKEN", "")
        end
        ActiveSupport::SecurityUtils.secure_compare(token, expected)
      },
      basic_authenticator: nil,
      application_controller_mixin: Module.new do
        def self.included(base)
          base.class_eval do
            rescue_from StandardError do |exception|
              handle_scim_error(exception)
            end
          end
        end

        private

        def handle_scim_error(exception)
          Rails.logger.error("SCIM error: #{exception.message}")
          render json: {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: exception.message,
            status: "500"
          }, status: :internal_server_error
        end
      end
    )
  end
end
