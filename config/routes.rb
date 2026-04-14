# frozen_string_literal: true

Rails.application.routes.draw do
  if ENV.key?("PWP_PUBLIC_GATEWAY")
    draw :public_users
    draw :public_pushes

    # Add a route that handles the root path and returns a 404 error
    root to: proc { |env| [404, {"Content-Type" => "text/html"}, ["<h1>Not Found</h1>"]] }
  else
    draw :admin
    draw :madmin
    draw :users
    draw :pushes
    draw :pwp_api

    apipie

    get "/pages/*id" => "pages#show", :as => :page, :format => false

    mount Mailbin::Engine => :mailbin if Rails.env.development?

    draw :redirects
    draw :legacy_devise
    draw :legacy_pages
    draw :legacy_pushes

    root to: "pushes#new"
  end

  # Health check endpoint that returns a simple 200 OK response
  get "/up" => proc { |env|
    [200, {"Content-Type" => "text/html"}, ["<html style='background:green;width:100%;height:100vh'></html>"]]
  }

  # JSON health check endpoint with database connectivity verification
  get "/healthz" => "health#healthz"

  # SCIM 2.0 provisioning endpoint for Azure Entra ID user sync
  _scim_on = begin; AppSetting.scim_enabled?; rescue; ActiveModel::Type::Boolean.new.cast(ENV.fetch("PWP__SCIM__ENABLED", false)); end
  if defined?(Scimitar) && _scim_on
    namespace :scim_v2, path: "scim/v2" do
      get "ServiceProviderConfig", to: "service_provider_configurations#show"
      get "Schemas", to: "schemas#index"
      get "Schemas/:id", to: "schemas#show"
      get "ResourceTypes", to: "resource_types#index"
      get "ResourceTypes/:id", to: "resource_types#show"

      resources :users, controller: :users
    end
  end

  post "/csp-violation-report", to: "csp_reports#create"
end
