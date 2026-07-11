Rails.application.routes.draw do
  root to: "public/home#show", as: :public_root
  get "/about", to: "public/about#show", as: :public_about
  get "/about/principles", to: "public/about#principles", as: :public_principles

  scope "products" do
    get "/ai-employee",         to: "public/ai_employee#show",  as: :public_product_ai_employee
    get "/marketing-flow",      to: redirect("/products/ai-employee")
    get "/safe-automation",     to: redirect("/products/ai-employee")
  end

  resources :industries, controller: "public/industries", only: [:index, :show]
  get "/case-studies", to: "public/case_studies#index", as: :public_case_studies
  get "/case-studies/:slug", to: "public/case_studies#show", as: :public_case_study

  scope "pricing" do
    get "/",                  to: "public/pricing#show", as: :public_pricing
  end

  # Legal pages under /p/:slug
  get "/p/:slug", to: "public/pages#show", constraints: { slug: /[a-z\-]+/ }, as: :public_page

  scope "contact" do
    get  "/",        to: "public/contacts#new",   as: :public_contact
    post "/",        to: "public/contacts#create"
    get  "/thanks",  to: "public/contacts#thanks", as: :public_contact_thanks
  end

  # 셀프 회원가입 비활성화: 공개 사이트에서는 "초기 도입 상담 신청"만 안내
  # 운영자 초대 기반 가입만 허용 (/signup_invitations/...)
  match "/signup", via: [:get, :post], to: redirect("/contact")
  get  "/login",             to: "user_sessions#new",  as: :new_user_session
  post "/login",             to: "user_sessions#create", as: :user_sessions
  delete "/logout",          to: "user_sessions#destroy", as: :logout

  # Magic link (user login)
  get  "/magic_link",          to: "user_magic_links#new",     as: :new_user_magic_link
  post "/magic_link",        to: "user_magic_links#create",  as: :user_magic_link_create
  get  "/magic_link/:token",  to: "user_magic_links#show",    as: :user_magic_link, constraints: { token: /[^\/]+/ }

  # Password reset (placeholder)
  get  "/password/new",       to: "passwords#new",         as: :new_password
  patch "/password",          to: "passwords#update",      as: :password
  get  "/password/forgot",    to: "passwords#forgot",      as: :forgot_password
  post "/password/forgot",    to: "passwords#request_reset", as: :request_reset_password

  # Business app
  namespace :app do
    root to: "dashboards#show", as: :root
    get  "/business_profile",         to: "business_profiles#show", as: :business_profile
    get  "/business_profile/edit",    to: "business_profiles#edit", as: :edit_business_profile
    patch "/business_profile",        to: "business_profiles#update", as: nil
    resources :ai_employees, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      collection do
        post :create_default
      end
      member do
        post :duplicate
        post :test_message
        post :add_memory
        delete :remove_memory
        get  :preview_persona
      end
    end
    get  "/knowledge",                to: "knowledge_sources#index",    as: :knowledge_sources
    get  "/knowledge/new",            to: "knowledge_sources#new",      as: :new_knowledge_source
    post "/knowledge",                to: "knowledge_sources#create",   as: nil
    get  "/knowledge/sources/:id",    to: "knowledge_sources#show",     as: :knowledge_source
    get  "/knowledge/sources/:id/edit", to: "knowledge_sources#edit",   as: :edit_knowledge_source
    patch "/knowledge/sources/:id",   to: "knowledge_sources#update",   as: nil
    delete "/knowledge/sources/:id",  to: "knowledge_sources#destroy",  as: nil
    post "/knowledge/sources/:id/sync", to: "knowledge_sources#sync",   as: :knowledge_source_sync
    post "/knowledge/sources/:id/mark_failed", to: "knowledge_sources#mark_failed", as: :knowledge_source_mark_failed
    post "/knowledge/sources/:id/reindex", to: "knowledge_sources#reindex", as: :knowledge_source_reindex
    get  "/faqs",                   to: "faqs#index",                as: :faqs
    get  "/faqs/new",               to: "faqs#new",                 as: :new_faq
    post "/faqs",                   to: "faqs#create"
    get  "/faqs/:id",               to: "faqs#show",                as: :faq
    get  "/faqs/:id/edit",          to: "faqs#edit",                as: :edit_faq
    patch "/faqs/:id",              to: "faqs#update"
    delete "/faqs/:id",             to: "faqs#destroy"
    get  "/products",               to: "products#index",            as: :products
    get  "/products/new",           to: "products#new",              as: :new_product
    post "/products",               to: "products#create"
    get  "/products/:id",           to: "products#show",             as: :product
    get  "/products/:id/edit",      to: "products#edit",             as: :edit_product
    patch "/products/:id",          to: "products#update"
    delete "/products/:id",         to: "products#destroy"
    get  "/services",               to: "services#index",            as: :services
    get  "/services/new",           to: "services#new",              as: :new_service
    post "/services",               to: "services#create"
    get  "/services/:id",           to: "services#show",             as: :service
    get  "/services/:id/edit",      to: "services#edit",             as: :edit_service
    patch "/services/:id",          to: "services#update"
    delete "/services/:id",         to: "services#destroy"
    get  "/channels",               to: "channels#index",            as: :channels
    get  "/channels/new",           to: "channels#new",              as: :new_channel
    post "/channels",               to: "channels#create"
    get  "/channels/:id",           to: "channels#show",             as: :channel
    get  "/channels/:id/edit",      to: "channels#edit",             as: :edit_channel
    patch "/channels/:id",          to: "channels#update"
    post "/channels/:id/activate",  to: "channels#activate",         as: :channel_activate
    post "/channels/:id/pause",     to: "channels#pause",            as: :channel_pause
    post "/channels/:id/resume",    to: "channels#resume",           as: :channel_resume
    delete "/channels/:id",         to: "channels#destroy",          as: nil
    # Engagement 자동 응대 (Instagram/Threads)
    resources :engagements, only: [:show, :create]
    get  "/content",                to: "content_items#pending_for_review", as: :pending_for_review
    get  "/content/items",          to: "content_items#index",       as: :content_items
    get  "/content/items/new",      to: "content_items#generate",    as: :new_content_item
    post "/content/items",          to: "content_items#generate",    as: :generate_content_item
    get  "/content/items/:id/edit", to: "content_items#edit",        as: :edit_content_item
    get  "/content/items/:id",      to: "content_items#show",        as: :content_item
    post "/content/items/:id/publish_to_channel", to: "content_items#publish_to_channel", as: nil
    patch "/content/items/:id",     to: "content_items#update",      as: :update_content_item
    post "/content/items/:id/schedule",  to: "content_items#schedule",     as: :schedule_content_item
    post "/content/items/:id/publish",   to: "content_items#publish_now",  as: :publish_content_item
    post "/content/items/:id/approve",   to: "content_items#approve",      as: :approve_content_item
    post "/content/items/:id/reject",    to: "content_items#reject",       as: :reject_content_item
    post "/content/items/:id/archive",   to: "content_items#archive",      as: :archive_content_item
    get  "/automations",                to: "automation_rules#dashboard",  as: :automation_dashboard
    get  "/automations/rules",          to: "automation_rules#index",      as: :automation_rules
    get  "/automations/rules/new",      to: "automation_rules#new",        as: :new_automation_rule
    post "/automations/rules",          to: "automation_rules#create",     as: nil
    get  "/automations/rules/:id",      to: "automation_rules#show",       as: :automation_rule
    get  "/automations/rules/:id/edit", to: "automation_rules#edit",       as: :edit_automation_rule
    patch "/automations/rules/:id",     to: "automation_rules#update"
    delete "/automations/rules/:id",    to: "automation_rules#destroy"
    post "/automations/rules/:id/activate", to: "automation_rules#activate",  as: :activate_automation_rule
    post "/automations/rules/:id/pause",    to: "automation_rules#pause",     as: :pause_automation_rule
    post "/automations/rules/:id/run_now",  to: "automation_rules#run_now",   as: :run_automation_rule
    get  "/automations/executions",     to: "automation_executions#index", as: :automation_executions
    get  "/automations/executions/:id", to: "automation_executions#show",  as: :automation_execution
    get  "/conversations",                to: "conversations#index",        as: :conversations
    get  "/conversations/:id",            to: "conversations#show",         as: :conversation
    get  "/handoffs",                  to: "handoffs#index",   as: :handoffs
    get  "/handoffs/:id",              to: "handoffs#show",    as: :handoff
    get  "/handoffs/:id/edit",         to: "handoffs#edit",    as: :edit_handoff
    patch "/handoffs/:id",             to: "handoffs#update"
    post "/handoffs/:id/acknowledge",  to: "handoffs#acknowledge", as: :acknowledge_handoff
    post "/handoffs/:id/resolve",      to: "handoffs#resolve", as: :resolve_handoff
    get  "/plans",                     to: "plans#index",      as: :plans
    get  "/billing",                   to: "billing#index",    as: :billing
    post "/billing/pay",               to: "billing#pay",       as: :billing_pay
    post "/billing/subscribe",         to: "billing#subscribe", as: :billing_subscribe
    post "/billing/cancel",            to: "billing#cancel_subscription", as: :billing_cancel
    get  "/billing/invoice/:id",       to: "billing#show",     as: :billing_invoice
    get  "/referrals",                 to: "referrals#index",  as: :referrals
    post "/referrals",                 to: "referrals#create", as: nil
    get  "/reports",                          to: "reports#index",                 as: :reports
    get  "/reports/weekly/:id",               to: "reports#show_weekly",           as: :report_weekly
    post "/reports/trigger_daily",            to: "reports#trigger_daily",         as: :trigger_daily_reports
    post "/reports/trigger_weekly",           to: "reports#trigger_weekly",        as: :trigger_weekly_reports
    get  "/delivery_logs",                    to: "delivery_logs#index",           as: :delivery_logs
    get  "/settings",                  to: "settings#show",   as: :settings
    patch "/settings",                 to: "settings#update"
    get  "/termination",               to: "terminations#new", as: :new_termination
    post "/termination",               to: "terminations#create", as: :termination
    get  "/termination/new",           to: "terminations#new",  as: :new_termination_alt
    get  "/termination/confirm",       to: "terminations#confirm", as: :confirm_termination
    get     "/data_exports",              to: "data_exports#index",    as: :data_exports
    get     "/data_exports/new",          to: "data_exports#new",      as: :new_data_export
    post    "/data_exports",              to: "data_exports#create"
    get     "/data_exports/:id",          to: "data_exports#show",     as: :data_export
    get     "/data_exports/:id/download", to: "data_exports#download", as: :download_data_export
    delete  "/data_exports/:id",          to: "data_exports#destroy"
    get  "/deletion_requests",         to: "deletion_requests#index",   as: :deletion_requests
    get  "/deletion_requests/new",     to: "deletion_requests#new",     as: :new_deletion_request
    post "/deletion_requests",         to: "deletion_requests#create"
    get  "/deletion_requests/:id",     to: "deletion_requests#show",    as: :deletion_request
    get  "/reports/show",                  to: "reports#show",                as: :report_show
    get  "/reports/show/:id",              to: "reports#show",                as: :report_show_id
    get  "/analytics",                 to: "analytics#show",            as: :analytics
    get  "/analytics/export",          to: "analytics#export",          as: :export_analytics
    get  "/csat/new",                  to: "csat#new",                  as: :new_csat
    resources :csat, only: [:create]

    # Hermes Runtime Configuration (bundle + heartbeat + version + rollback)
    resources :runtime_configs do
      member do
        post :activate
        post :rollback
      end
      collection do
        post :heartbeat
      end
    end
  end

  # Platform admin
  namespace :platform do
    root to: "dashboards#show"
    get  "/login",          to: "sessions#new"
    post "/login",          to: "sessions#create"
    delete "/logout",       to: "sessions#destroy"

    # Magic link (platform staff login)
    post "/magic_link",        to: "magic_links#create",  as: :magic_link_create
    get  "/magic_link/:token",  to: "magic_links#show",    as: :magic_link, constraints: { token: /[^\/]+/ }

    resources :accounts do
      member { post :suspend; post :reactivate }
    end
    resources :platform_staff, only: [:index, :show]
    resources :inquiries
    resources :feature_flags
    resources :audit_events, only: [:index, :show]
    resources :incidents
    resources :model_catalog_entries
    resources :plans
    resources :industries, controller: "industries"
    resources :industry_templates, controller: "industries"
    resources :prompt_templates
    resources :contracts
    get  "/billings", to: "billings#index", as: :billings
    get  "/reports", to: "reports#show", as: :reports

    # Hermes Agent integration (consume automation results from real Hermes runtime)
    get  "/hermes",              to: "hermes#index",       as: :hermes
    post "/hermes/test",         to: "hermes#test",        as: :hermes_test
    get  "/hermes/executions",   to: "hermes#executions",  as: :hermes_executions
    get  "/hermes/audit",        to: "hermes#audit",       as: :hermes_audit

    # 공지사항 (전역/계정별, 사업자에게 노출)
    resources :announcements do
      member do
        post :publish
        post :archive
      end
    end
  end

  # ActionCable mount (real-time notifications)
  mount ActionCable.server => "/cable"

  # Dev-only convenience: bypass CSRF, sign in a platform staff / business user with given email
  post "/dev_login/platform", to: "dev_overrides#platform_login"
  post "/dev_login/business", to: "dev_overrides#business_login"

  # API root (service-account authenticated)
  namespace :api do
    resources :accounts
    resources :ai_employees
    resources :content_items
    resources :automation_executions
    resources :publications

    # Hermes Runtime Configuration Bundle + Heartbeat API
    get  "/runtime_configs/current",                   to: "runtime_configs#current"
    resources :runtime_configs, only: [:create] do
      member do
        post :activate
        post :rollback
      end
      collection do
        post :heartbeat
      end
    end
  end

  # Errors
  match "/403", to: "public/errors#forbidden", via: :all, as: :err_403
  match "/404", to: "public/errors#not_found", via: :all, as: :err_404
  match "/500", to: "public/errors#server_error", via: :all, as: :err_500
end
