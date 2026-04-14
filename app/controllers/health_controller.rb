# frozen_string_literal: true

class HealthController < ActionController::Base
  def healthz
    db_status = begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      "connected"
    rescue => e
      "disconnected"
    end

    status_code = db_status == "connected" ? :ok : :service_unavailable

    render json: {
      status: status_code == :ok ? "ok" : "error",
      version: File.read(Rails.root.join("VERSION")).strip,
      database: db_status,
      timestamp: Time.current.iso8601
    }, status: status_code
  end
end
