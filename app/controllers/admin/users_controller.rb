module Admin
  class UsersController < ::AdminController
    def index
      @admin_users = User.where(admin: true).order(:email)
      @regular_users = User.where(admin: [false, nil]).order(:email).page(params[:page]).per(25)
    end

    def promote
      @user = User.find(params[:id])

      begin
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array(["UPDATE users SET admin=true WHERE users.id=?", @user.id])
        )
        @user.reload

        redirect_to admin_users_path, notice: "#{@user.email} has been promoted to administrator."
      rescue => e
        redirect_to admin_users_path, alert: "Failed to promote #{@user.email} to administrator: #{e.message}"
      end
    end

    def revoke
      @user = User.find(params[:id])

      # Prevent admin from revoking their own admin privileges
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot revoke your own administrator privileges."
        return
      end

      begin
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array(["UPDATE users SET admin=false WHERE users.id=?", @user.id])
        )
        @user.reload

        redirect_to admin_users_path, notice: "Administrator privileges have been revoked from #{@user.email}."
      rescue => e
        redirect_to admin_users_path, alert: "Failed to revoke administrator privileges from #{@user.email}: #{e.message}"
      end
    end

    def new
      @user = User.new
    end

    def create
      password = if params[:user][:password].present?
        params[:user][:password]
      else
        Devise.friendly_token[0, 20]
      end

      @user = User.new(email: params[:user][:email], password: password)
      @user.admin = params[:user][:admin] == "1"
      @user.skip_confirmation! if @user.respond_to?(:skip_confirmation!)

      if @user.save
        if Settings.enable_user_account_emails && @user.respond_to?(:send_reset_password_instructions)
          @user.send_reset_password_instructions
          redirect_to admin_users_path, notice: _("User created and password reset email sent to %{email}.") % { email: @user.email }
        else
          redirect_to admin_users_path, notice: _("User %{email} created. Share the temporary password with them securely.") % { email: @user.email }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def send_reset_password
      @user = User.find(params[:id])
      if @user.respond_to?(:send_reset_password_instructions)
        @user.send_reset_password_instructions
        redirect_to admin_users_path, notice: _("Password reset instructions sent to %{email}.") % { email: @user.email }
      else
        redirect_to admin_users_path, alert: _("Password reset is not available.")
      end
    end

    def destroy
      @user = User.find(params[:id])

      # Prevent admin from deleting their own account
      if @user == current_user
        redirect_to admin_users_path, alert: _("You cannot delete your own account.")
        return
      end

      user_email = @user.email

      if @user.destroy
        redirect_to admin_users_path, notice: "User #{user_email} has been deleted."
      else
        error_message = @user.errors.full_messages.to_sentence.presence || "Unknown error"
        redirect_to admin_users_path, alert: "Failed to delete user #{user_email}: #{error_message}"
      end
    end

    private
  end
end
