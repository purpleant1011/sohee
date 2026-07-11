class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :business_profiles, dependent: :destroy
  has_many :ai_employees, dependent: :destroy
  has_many :automation_rules, dependent: :destroy
  has_many :content_items, dependent: :destroy
  has_many :channel_connections, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contracts, class_name: "ContractTerm", dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :deposits, dependent: :destroy
  has_many :weekly_reports, dependent: :destroy
  has_many :delivery_logs, dependent: :destroy
  has_many :audit_events, dependent: :nullify
  has_many :automation_executions, dependent: :nullify
  has_many :handoffs, dependent: :nullify
  has_many :usage_metrics, dependent: :nullify
  has_many :cost_settings, dependent: :nullify
  has_many :reviews, dependent: :nullify
  has_many :runtime_configs, dependent: :destroy
  has_many :runtime_heartbeats, dependent: :destroy
  has_many :csat_responses, dependent: :destroy
  has_many :inquiries, dependent: :nullify
  has_many :publication_attempts, dependent: :nullify
  has_many :approvals, dependent: :nullify
  has_many :knowledge_sources, dependent: :nullify
  has_many :prompts, dependent: :nullify
  has_many :calendar_events, dependent: :nullify
  has_many :faqs, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :services, dependent: :nullify
  has_many :referrals, dependent: :nullify
  has_many :data_export_requests, dependent: :nullify
  has_many :deletion_requests, dependent: :nullify
  has_many :invoices, dependent: :nullify
  has_many :knowledge_documents, dependent: :nullify
  has_one :primary_business_profile, -> { order(:created_at) }, class_name: "BusinessProfile", dependent: :nullify
  def business_profile
    business_profiles.first || business_profiles.build
  end
  has_many :channels, through: :channel_connections

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9_\-]+\z/ }
  validates :timezone, presence: true

  def paused?; status == "paused"; end
  def terminated?; status == "terminated"; end
  def active?; status == "active"; end

  def owner_user
    memberships.where(role: "owner").first&.user
  end
end
