# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout "login"

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    super
  rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError,
         Net::SMTPFatalError, Net::SMTPUnknownError, Net::OpenTimeout,
         Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
    Rails.logger.error("Failed to send password reset email: #{e.class} - #{e.message}")
    flash[:warning] = _("Your request was processed but the email could not be sent. Please contact your administrator.")
    redirect_to new_user_session_path
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  protected

  def sign_in_after_reset_password?
    return false unless Devise.sign_in_after_reset_password

    !resource.otp_required_for_login?
  end
end
