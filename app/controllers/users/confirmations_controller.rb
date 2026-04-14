# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  layout "login"

  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    super
  rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError,
         Net::SMTPFatalError, Net::SMTPUnknownError, Net::OpenTimeout,
         Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
    Rails.logger.error("Failed to send confirmation email: #{e.class} - #{e.message}")
    flash[:warning] = _("Your request was processed but the email could not be sent. Please contact your administrator.")
    redirect_to new_user_session_path
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    if params[:go].present?
      super
    else
      render "show", layout: "bare"
    end
  end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
end
