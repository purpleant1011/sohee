# frozen_string_literal: true

# Discord-Native Job 베이스 (P1)
# 원칙: 모든 Job은 멱등(같은 ID 재실행 안전), 감사 로그 자동, 실패는 RuntimeSync에 기록
class DiscordNativeJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  before_perform :record_start
  after_perform :record_success
  rescue_from(StandardError) { |e| record_failure(e) }

  private

  def record_start
    AuditEvent.create!(
      actor_kind: "system",
      actor_label: "discord_native_job:#{self.class.name}",
      action: "job.started",
      target: target_label,
      metadata: job_metadata
    )
  end

  def record_success
    AuditEvent.create!(
      actor_kind: "system",
      actor_label: "discord_native_job:#{self.class.name}",
      action: "job.completed",
      target: target_label,
      metadata: job_metadata
    )
  end

  def record_failure(error)
    AuditEvent.create!(
      actor_kind: "system",
      actor_label: "discord_native_job:#{self.class.name}",
      action: "job.failed",
      target: target_label,
      metadata: job_metadata.merge(error: error.class.name, message: error.message)
    )
    Rails.logger.error("[discord-native] #{self.class.name} failed: #{error.message}")
  end

  def target_label
    arguments.first.is_a?(Integer) ? "#{model_class}##{arguments.first}" : arguments.first.to_s
  end

  def model_class
    self.class.name.sub("Job", "").singularize
  end

  def job_metadata
    { job_id: job_id, queue: queue_name, attempts: executions }
  end
end