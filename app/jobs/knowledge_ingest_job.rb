# frozen_string_literal: true

# Knowledge Source를 RAG 인덱싱하는 Job
# 1) 파일/URL/텍스트 → 텍스트 추출
# 2) 청크 분할
# 3) KnowledgeDocument로 저장
class KnowledgeIngestJob < ApplicationJob
  queue_as :default

  def perform(knowledge_source_id)
    source = KnowledgeSource.find_by(id: knowledge_source_id)
    return unless source

    source.update!(status: "processing", error_message: nil)

    # 1) 텍스트 추출
    text = extract_text(source)
    if text.blank?
      source.update!(status: "failed", error_message: "텍스트를 추출할 수 없습니다.")
      return
    end

    # 2) 청크 분할 (1000자 단위, 200자 오버랩)
    chunks = split_into_chunks(text, chunk_size: 1000, overlap: 200)

    # 3) KnowledgeDocument 저장
    chunks.each_with_index do |chunk, idx|
      KnowledgeDocument.create!(
        account: source.account,
        knowledge_source_id: source.id,
        raw_text: chunk,
        normalized_text: chunk.strip,
        mime_type: source.file.attached? ? source.file.content_type : "text/plain",
        byte_size: chunk.bytesize,
        checksum_sha256: Digest::SHA256.hexdigest(chunk),
        status: "ready",
        indexed_at: Time.current,
        version: 1,
        pii_warnings_count: detect_pii(chunk).size
      )
    end

    source.update!(status: "ready")
    Rails.logger.info("[KnowledgeIngestJob] #{source.id} → #{chunks.size} chunks")
  rescue => e
    source&.update!(status: "failed", error_message: "#{e.class}: #{e.message[0, 200]}")
    Rails.logger.error("[KnowledgeIngestJob] #{knowledge_source_id} failed: #{e.class}: #{e.message[0, 200]}")
  end

  private

  def extract_text(source)
    if source.file.attached?
      blob = source.file.download
      detect_and_decode(blob, source.file.content_type)
    elsif source.url.present?
      fetch_url(source.url)
    elsif source.respond_to?(:content) && source.content.present?
      source.content
    else
      ""
    end
  end

  def detect_and_decode(bytes, content_type)
    # PDF는 외부 라이브러리 없으면 빈 텍스트
    return "[PDF 파일 — 텍스트 추출 라이브러리 미설치]" if content_type.to_s.include?("pdf")
    # 기본은 utf-8로 가정
    bytes.force_encoding("UTF-8").scrub
  end

  def fetch_url(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 15
    req = Net::HTTP::Get.new(uri.request_uri)
    res = http.request(req)
    return "" unless res.code.to_i < 400
    # HTML → 텍스트 단순 추출
    html = res.body.to_s
    html.gsub(/<script[^>]*>.*?<\/script>/mi, "")
        .gsub(/<style[^>]*>.*?<\/style>/mi, "")
        .gsub(/<[^>]+>/, " ")
        .gsub(/\s+/, " ")
        .strip
  rescue => e
    ""
  end

  def split_into_chunks(text, chunk_size: 1000, overlap: 200)
    return [] if text.blank?
    chunks = []
    pos = 0
    while pos < text.length
      chunk = text[pos, chunk_size]
      break if chunk.blank?
      chunks << chunk.strip
      pos += (chunk_size - overlap)
    end
    chunks
  end

  # 매우 단순한 PII 감지 (전화번호, 이메일)
  def detect_pii(text)
    pii = []
    pii << "phone" if text.match?(/\d{2,3}-\d{3,4}-\d{4}/)
    pii << "email" if text.match?(/[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}/)
    pii
  end
end