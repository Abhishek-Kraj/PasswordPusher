authenticated :user, lambda { |u| u.admin? } do
  get "/admin", to: "admin#index", as: :admin_root

  namespace :admin do
    resources :users, only: [:index, :destroy] do
      member do
        patch :promote
        patch :revoke
      end
    end
    resources :integrations, only: [:index]
  end

  mount MissionControl::Jobs::Engine, at: "/admin/jobs" if defined?(::MissionControl::Jobs::Engine)
end
