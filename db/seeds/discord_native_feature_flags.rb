# Discord-Native FeatureFlag 시드 (P1)
# 원칙 14: Antigravity CLI는 기본 OFF (개발자만 opt-in)
# 원칙 15: 모델 ID/Provider 하드코딩 금지 → FeatureFlag로 게이트
# 스키마: account_id + key (account_id nil = 글로벌)

[
  {
    key: "discord_native_enabled",
    enabled: false, # P1 코드 단계 완료 후 운영자가 켬
    description: "Discord-Native 확장 전체 ON/OFF. false면 워커/엔드포인트가 stub 모드."
  },
  {
    key: "antigravity_cli_enabled",
    enabled: false, # 원칙 14: 기본 OFF
    description: "Antigravity CLI Dev Provider 허용. 프로덕션에서 절대 true로 설정 금지."
  },
  {
    key: "sohee_gemini_provider_active",
    enabled: true,
    description: "Gemini Provider 3종 라우팅 활성화. 키 없으면 stub 응답."
  },
  {
    key: "sohee_change_proposal_auto_expiry",
    enabled: true,
    description: "ChangeProposal 24시간 미결정 시 자동 만료."
  },
  {
    key: "sohee_memory_recall_enabled",
    enabled: true,
    description: "BusinessMemory recall (대화 컨텍스트 주입) 활성화."
  }
].each do |attrs|
  flag = FeatureFlag.find_or_initialize_by(key: attrs[:key], account_id: nil)
  flag.assign_attributes(
    enabled: attrs[:enabled],
    value: attrs[:description]
  )
  flag.save!
end

puts "Seeded #{FeatureFlag.count} feature flags"