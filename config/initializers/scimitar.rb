# frozen_string_literal: true

if defined?(Scimitar) && Settings.respond_to?(:scim) && ActiveModel::Type::Boolean.new.cast(Settings.scim&.enabled)
  Rails.application.config.to_prepare do
    Scimitar.engine_configuration = Scimitar::EngineConfiguration.new(
      token_authenticator: proc { |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(
          token,
          Settings.scim.bearer_token
        )
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
