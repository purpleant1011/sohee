module Public
  class CaseStudiesController < BaseController
    # 검증 전 수치·실명·지역명은 절대 노출하지 않습니다.
    # 공개 사례는 "1인 뷰티샵 초기 파트너" / "수도권 뷰티 서비스 사업장" / "초기 파트너 A" 등으로 익명화되어 제공됩니다.
    CASE_STUDIES = [
      {
        slug: "initial-partner-beauty-2026q3",
        industry: "1인 뷰티샵 (익명)",
        client_role: "오너",
        summary: "초기 파트너 매장. 사장님이 직접 설정한 AI 직원이 일정에 맞춰 안내 콘텐츠를 초안 작성하고, 검수 후 채널 게시.",
        metrics: nil, # 검증 전 수치 비공개
        consent_public: true,
        source: "internal-pilot",
        blocks: [
          { kind: "context", title: "배경", text: "수도권 1인 뷰티샵. 사장님 1인 운영이며 자동화에 익숙하지 않으나 홍보·문의응대 부담은 큼." },
          { kind: "configuration", title: "AI 직원 설정", text: "톤: 차분한 존댓말 / 출처 인용 의무 / 금지 어휘(100% 안전·시술 후 즉시 변화 등)." },
          { kind: "flow", title: "주간 흐름", text: "월요일 주제 입력 → AI 직원 초안 → 사장님 검수 → 자동 게시 → 주간 요약." },
          { kind: "result", title: "검증 중 항목", text: "브랜드 기준 정리 / 콘텐츠 품질 / 기초문의 분류 / 사진 상담 흐름 / 원장님 인계 루틴" }
        ]
      },
      {
        slug: "consultation-flow-2026q3",
        industry: "예약제 뷰티 서비스 (익명)",
        client_role: "오너",
        summary: "초기 파트너 매장. 시즌성·반복 문의를 AI 직원이 FAQ·지식베이스로 응대하고, 사람 응답이 필요한 항목은 원장님 알림으로 전달.",
        metrics: nil, # 검증 전 수치 비공개
        consent_public: true,
        source: "internal-pilot",
        blocks: [
          { kind: "context", title: "배경", text: "예약제 뷰티 서비스 사업장. 예약·가격·시술 가능 여부 문의가 반복적으로 들어옴." },
          { kind: "configuration", title: "AI 직원 설정", text: "톤: 사무체 / 민감 정보 수집 금지 / 확신도 일정 수준 미만은 사람 상담 전환." },
          { kind: "flow", title: "응대 흐름", text: "메시지 수신 → FAQ·지식 검색 → 초안 작성 → 안전 검증 → 사람 상담 전환 여부 결정." },
          { kind: "result", title: "검증 중 항목", text: "응대 분류 정확도 / 사진 상담 연결 / 원장님 인계 품질 / 응대 안전성" }
        ]
      }
    ].freeze

    def index
      @case_studies = CASE_STUDIES
    end

    def show
      @case_study = CASE_STUDIES.find { |c| c[:slug] == params[:slug] }
      raise ActionController::RoutingError, "Not Found" unless @case_study
    end
  end
end