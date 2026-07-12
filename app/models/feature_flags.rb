# frozen_string_literal: true

# FeatureFlag 게이트 (Discord-Native) — 원칙 14, 15
# 실제 스키마: key + account_id + enabled + value
# 글로벌 플래그는 account_id: nil
module FeatureFlags
  class DisabledError < StandardError; end

  CACHE_TTL = 10.seconds

  module_function

  def enabled?(key, account: nil)
    cache_key = "feature_flag:#{account&.id || 'global'}:#{key}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      flag = FeatureFlag.find_by(key: key.to_s, account_id: account&.id)
      flag&.enabled == true
    end
  end

  def disabled?(key, account: nil)
    !enabled?(key, account: account)
  end

  def ensure!(key, account: nil)
    return if enabled?(key, account: account)
    raise FeatureFlags::DisabledError, "Feature flag #{key} is disabled"
  end

  def flush_cache!
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end
end