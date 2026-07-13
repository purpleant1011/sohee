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

  # 셀프 회원가입 (사업자만 가능, 14일 무료 체험 자동 부여)
  # 셀프 회원가입 폐쇄 (2026-07-12 리뉴얼). 신규 고객사는 도입 상담 후 운영팀이 Platform::AccountsController#create로 등록한다.
  get  "/signup", to: redirect("/contact", status: 302)
  # POST /signup은 외부에서 호출되어도 신규 가입이 발생하지 않도록 완전히 차단한다.
  post "/signup", to: ->(_env) { [410, { "Content-Type" => "text/html; charset=utf-8" }, ["Go away."]] }
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
    root to: "dashboards#show"
    get "/dashboard", to: "dashboards#show", as: :dashboard
    get    "/login",                 to: "sessions#new",     as: :login
    post   "/login",                 to: "sessions#create"
    delete "/logout",                to: "sessions#destroy", as: :logout
    get  "/business_profile",         to: "business_profiles#show", as: :business_profile
    get  "/business_profile/edit",    to: "business_profiles#edit", as: :edit_business_profile
    patch "/business_profile",        to: "business_profiles#update", as: nil
    # P1-5 (2026-07-12): 셋업 마법사. 사업자가 처음 들어왔을 때 단계별로 사업장 정보를 입력.
    get    "/setup",                  to: "setups#show",              as: :setup
    patch  "/setup",                  to: "setups#update",            as: :update_setup
    get    "/setup/skip",             to: "setups#skip",              as: :skip_setup
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
    # P0-3 (2026-07-12): faqs#show placeholder 라우트 제거. FAQ 상세는 목록+편집 인라인으로 처리한다.
    # get  "/faqs/:id",               to: "faqs#show",                as: :faq
    get  "/faqs/:id/edit",          to: "faqs#edit",                as: :edit_faq
    patch "/faqs/:id",              to: "faqs#update"
    delete "/faqs/:id",             to: "faqs#destroy"
    get  "/knowledge_gaps",            to: "knowledge_gaps#index",      as: :knowledge_gaps
    get  "/knowledge_gaps/:id",        to: "knowledge_gaps#show",       as: :knowledge_gap
    post "/knowledge_gaps",            to: "knowledge_gaps#create"
    post "/knowledge_gaps/:id/convert", to: "knowledge_gaps#convert",  as: :convert_knowledge_gap
    post "/knowledge_gaps/:id/dismiss", to: "knowledge_gaps#dismiss",  as: :dismiss_knowledge_gap
    get  "/products",               to: "products#index",            as: :products
    get  "/products/new",           to: "products#new",              as: :new_product
    post "/products",               to: "products#create"
    # P0-3 (2026-07-12): products#show placeholder 라우트 제거. 가격표/상품은 목록+편집 인라인.
    # get  "/products/:id",           to: "products#show",             as: :product
    get  "/products/:id/edit",      to: "products#edit",             as: :edit_product
    patch "/products/:id",          to: "products#update"
    delete "/products/:id",         to: "products#destroy"
    # P0-3 (2026-07-12): services placeholder 라우트 제거. 매장 정보 메뉴는 products로 단일화한다.
    # get  "/services",               to: "services#index",            as: :services
    # get  "/services/new",           to: "services#new",              as: :new_service
    # post "/services",               to: "services#create"
    # get  "/services/:id",           to: "services#show",             as: :service
    # get  "/services/:id/edit",      to: "services#edit",             as: :edit_service
    # patch "/services/:id",          to: "services#update"
    # delete "/services/:id",         to: "services#destroy"
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
    get  "/content/items/new",      to: "content_items#new",        as: :new_content_item
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
    # P0-3 (2026-07-12): automation_dashboard placeholder 라우트 제거. 자동화 모니터링은 운영자 콘솔로 이동.
    # get  "/automations",                to: "automation_rules#dashboard",  as: :automation_dashboard
    get  "/automations/rules",          to: "automation_rules#index",      as: :automation_rules
    get  "/automations/rules/new",      to: "automation_rules#new",        as: :new_automation_rule
    post "/automations/rules",          to: "automation_rules#create",     as: nil
    get  "/automations/rules/:id",      to: "automation_rules#show",       as: :automation_rule
    get  "/automations/rules/:id/edit", to: "automation_rules#edit",       as: :edit_automation_rule
    patch "/automations/rules/:id",     to: "automation_rules#update"
    delete "/automations/rules/:id",    to: "automation_rules#destroy"
    post "/automations/rules/:id/activate",  to: "automation_rules#activate",  as: :activate_automation_rule
    post "/automations/rules/:id/pause",    to: "automation_rules#pause",     as: :pause_automation_rule
    post "/automations/rules/:id/run_now",  to: "automation_rules#run_now",   as: :run_automation_rule
    # P0-3 (2026-07-12): automation_executions placeholder 라우트 제거. 자동화 실행 로그는 운영자 콘솔에서 본다.
    # get  "/automations/executions",     to: "automation_executions#index", as: :automation_executions
    # get  "/automations/executions/:id", to: "automation_executions#show",  as: :automation_execution
    get  "/conversations",                to: "conversations#index",        as: :conversations
    get  "/conversations/:id",            to: "conversations#show",         as: :conversation
    get  "/confirmations",                to: "confirmations#index",   as: :confirmations
    get  "/handoffs",                  to: "handoffs#index",   as: :handoffs
    get  "/handoffs/:id",              to: "handoffs#show",    as: :handoff
    get  "/handoffs/:id/edit",         to: "handoffs#edit",    as: :edit_handoff
    patch "/handoffs/:id",             to: "handoffs#update"
    post "/handoffs/:id/acknowledge",  to: "handoffs#acknowledge", as: :acknowledge_handoff
    post   "/handoffs/:id/resolve",      to: "handoffs#resolve", as: :resolve_handoff
    # P2-2 (2026-07-13): Discord 대화 카드 + ChangeProposal 승인 카드 (사업자 포털)
    get    "/discord",                     to: "discords#index",        as: :discord
    get    "/change_proposals",            to: "change_proposals#index", as: :change_proposals
    get    "/change_proposals/:id",        to: "change_proposals#show",  as: :change_proposal
    post   "/change_proposals/:id/approve", to: "change_proposals#approve", as: :approve_change_proposal
    post   "/change_proposals/:id/reject",  to: "change_proposals#reject",  as: :reject_change_proposal
    # P2-3 (2026-07-13): Hermes ACK / 메시지 동기화 가시화
    get    "/integrity",                   to: "integrities#show",      as: :integrity
    # P3-1 (2026-07-13): Integration Hub — 자동 게시 규칙 + 게시 이력 + test/official 분리
    # (기존 /automations/rules 라우트와 충돌 회피: as 이름 차별화)
    get    "/automation",                   to: "automation_rules#index", as: :automation_rules_v2
    get    "/automation/:id",               to: "automation_rules#show",  as: :automation_rule_v2
    post   "/automation/:id/approve",       to: "automation_rules#approve", as: :approve_automation_rule_v2
    post   "/automation/:id/pause",         to: "automation_rules#pause",   as: :pause_automation_rule_v2
    post   "/automation/:id/resume",        to: "automation_rules#resume",  as: :resume_automation_rule_v2
    get    "/publication_history",          to: "publication_attempts#index", as: :publication_history
    # P0-3 (2026-07-12): plans/billing/referrals placeholder 라우트 제거. 운영팀이 직접 협상한다.
    # get  "/plans",                     to: "plans#index",      as: :plans
    # get  "/billing",                   to: "billing#index",    as: :billing
    # post "/billing/pay",               to: "billing#pay",       as: :billing_pay
    # post "/billing/subscribe",         to: "billing#subscribe", as: :billing_subscribe
    # post "/billing/cancel",            to: "billing#cancel_subscription", as: :billing_cancel
    # get  "/billing/invoice/:id",       to: "billing#show",     as: :billing_invoice
    # get  "/referrals",                 to: "referrals#index",  as: :referrals
    # post "/referrals",                 to: "referrals#create", as: nil
    get  "/reports",                          to: "reports#index",                 as: :reports
    get  "/reports/weekly/:id",               to: "reports#show_weekly",           as: :report_weekly
    post "/reports/trigger_daily",            to: "reports#trigger_daily",         as: :trigger_daily_reports
    post "/reports/trigger_weekly",           to: "reports#trigger_weekly",        as: :trigger_weekly_reports
    get  "/delivery_logs",                    to: "delivery_logs#index",           as: :delivery_logs
    # P0-3 (2026-07-12): 사업자 화면에서 audit_events/safety_logs/runtime_configs 라우트 차단.
    # 운영자 콘솔로 이동 (P0-4).
    # get  "/audit_events",                     to: "audit_events#index",            as: :audit_events
    # get  "/safety_logs",                      to: "safety_logs#index",             as: :safety_logs
    # get  "/settings/runtime",                 to: "runtime_configs#index",         as: :runtime_configs
    get  "/settings",                  to: "settings#show",   as: :settings
    patch "/settings",                 to: "settings#update"
    get    "/settings/password",       to: "settings#password",        as: :settings_password
    patch  "/settings/password",       to: "settings#update_password"
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

    # P0-3 (2026-07-12): Hermes Runtime Configuration은 사업자 화면에서 차단. 운영자 콘솔로 이동 (P0-4).
    # resources :runtime_configs do
    #   member do
    #     post :activate
    #     post :rollback
    #   end
    #   collection do
    #     post :heartbeat
    #   end
    # end
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
    resources :safety_logs, only: [:index, :show]
    resources :runtime_configs, only: [:index, :show]
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
  post "/dev_login/clear_rate_limit", to: "dev_overrides#clear_rate_limit"

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
  # P1-3 (2026-07-12): 사업자 영역(/app/*)에서 매칭되지 않는 URL은 친화적 404 페이지로 보낸다.
  # 외부 도메인 + development 환경에서도 Rails 디버그 페이지(스택트레이스)가 노출되지 않도록 보호한다.
  match "*unmatched", to: "public/errors#not_found", via: :all, constraints: lambda { |req|
    req.path.start_with?("/app/")
  }

  # ============================================================
  # Discord-Native API (P1, 2026-07-12)
  # ============================================================
  # 워커(Discord Gateway / Hermes MCP / Gemini Conversation) ↔ Rails 내부 API
  # 인증: X-Internal-Token 헤더 (HERMES_MCP_TOKEN 또는 DISCORD_GATEWAY_SERVICE_TOKEN)
  # feature flag: discord_native_enabled
  namespace :api do
    namespace :v1 do
      # 헬스 체크는 인증 없이 외부 모니터링에서 호출 가능
      get "health", to: "health#show", as: :health

      namespace :discord do
        resources :events, only: [:create]
      end

      namespace :mcp do
        resources :invokes, only: [:create], controller: "invokes"
      end

      namespace :gemini do
        resources :calls, only: [:create], controller: "calls"
      end

      resources :runtime_syncs, only: [] do
        member do
          post :ack
          post :nack
        end
      end
    end
  end

  match "/404", to: "public/errors#not_found", via: :all, as: :err_404
  match "/500", to: "public/errors#server_error", via: :all, as: :err_500

  # ============================================================
  # Antigravity CLI OAuth 인증 상태 (P3, 2026-07-12)
  # ============================================================
  # agy CLI 의 자체 OAuth 결과를 워커로 확인 + 재인증 안내
  namespace :antigravity do
    get  "/status", to: "sessions#status", as: :status
    get  "/login",  to: "sessions#login",  as: :login
  end
end
