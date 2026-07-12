// Antigravity Agent Provider (개발용 — 원칙 12, 14)
// feature flag: antigravity_cli_enabled 가 true 일 때만 로딩

import type { Provider, ProviderConfig, ProviderKind, ProviderRequest, ProviderResponse } from "./provider.js";

export class AntigravityAgentProvider implements Provider {
  readonly kind: ProviderKind = "antigravity_agent";
  private readonly config: ProviderConfig;

  constructor(config: ProviderConfig) {
    this.config = config;
  }

  get isReady(): boolean {
    return Boolean(this.config.apiKey);
  }

  async invoke(_req: ProviderRequest): Promise<ProviderResponse> {
    if (!this.isReady) {
      return {
        text: "(antigravity_agent stub) not configured — set ANTIGRAVITY_AGENT_URL",
        provider: this.kind,
        model: this.config.model,
      };
    }
    // 실제 구현은 HTTP client가 Antigravity 에이전트와 통신
    return {
      text: "(antigravity_agent stub) TODO: implement HTTP call to Antigravity Agent",
      provider: this.kind,
      model: this.config.model,
    };
  }
}