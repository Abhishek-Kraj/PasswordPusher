# frozen_string_literal: true

module Admin
  class AuditLogsController < ::AdminController
    def index
      @audit_logs = AuditLog.includes(:push, :user).order(created_at: :desc)

      if params[:kind].present?
        @audit_logs = @audit_logs.where(kind: params[:kind])
      end

      if params[:email].present?
        user_ids = User.where("email LIKE ?", "%#{params[:email]}%").pluck(:id)
        @audit_logs = @audit_logs.where(user_id: user_ids)
      end

      if params[:date_from].present?
        @audit_logs = @audit_logs.where("created_at >= ?", params[:date_from].to_date.beginning_of_day)
      end

      if params[:date_to].present?
        @audit_logs = @audit_logs.where("created_at <= ?", params[:date_to].to_date.end_of_day)
      end

      @audit_logs = @audit_logs.page(params[:page]).per(50)

      load_stats
    end

    private

    def load_stats
      @total_count = AuditLog.count
      @today_count = AuditLog.where("created_at >= ?", Time.current.beginning_of_day).count
      @unique_users_count = AuditLog.where.not(user_id: nil).distinct.count(:user_id)
      @failed_count = AuditLog.where(kind: [:failed_view, :failed_passphrase]).count
    end
  end
end
