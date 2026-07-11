module ApplicationHelper
  REGION_ANON_PATTERNS = [
    /\b청라\w*/, /\b바이름\w*/, /\b이아름\w*/, /\b퍼플앤트\w*/, /\b김선영\w*/,
    /\bsinchang\w*/i, /\bbyreum\w*/i, /\bsohee\w*/i
  ].freeze

  PERSON_ANON_PATTERNS = [
    /\b바이름\w*/, /\b이아름\w*/, /\b김선영\w*/, /\b퍼플앤트\w*/,
    /\bbyreum\w*/i, /\bsohee\w*/i
  ].freeze

  EMAIL_ANON_REPL = "—"

  def anonymize_region(value)
    return "" if value.blank?
    out = value.to_s.dup
    REGION_ANON_PATTERNS.each { |re| out.gsub!(re, "—") }
    out
  end

  def anonymize_person(value)
    return "" if value.blank?
    out = value.to_s.dup
    PERSON_ANON_PATTERNS.each { |re| out.gsub!(re, "—") }
    out
  end

  def anonymize_email(value)
    return "" if value.blank?
    value.to_s.gsub(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/, EMAIL_ANON_REPL)
  end
end