# frozen_string_literal: true

class Users::UnlocksController < Devise::UnlocksController
  layout "login"

  # GET /resource/unlock/new
  # def new
  #   super
  # end

  # POST /resource/unlock
  def create
    super
  rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError,
         Net::SMTPFatalError, Net::SMTPUnknownError, Net::OpenTimeout,
         Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
    Rails.logger.error("Failed to send unlock email: #{e.class} - #{e.message}")
    flash[:warning] = _("Your request was processed but the email could not be sent. Please contact your administrator.")
    redirect_to new_user_session_path
  end

  # GET /resource/unlock?unlock_token=abcdef
  # def show
  #   super
  # end

  # protected

  # The path used after sending unlock password instructions
  # def after_sending_unlock_instructions_path_for(resource)
  #   super(resource)
  # end

  # The path used after unlocking the resource
  # def after_unlock_path_for(resource)
  #   super(resource)
  # end
end
