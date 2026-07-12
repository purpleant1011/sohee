// Rails 내부 API 호출 클라이언트
// 원칙: 멱등키, X-Internal-Token, 타임아웃, 재시도

import { config } from "./config.js";
import { logger } from "./logger.js";

interface RailsEventPayload {
  snowflake_id: string;
  guild_id: string | null;
  channel_id: string;
  author_discord_id: string;
  kind: string;
  content_raw: string;
  attachments_meta: unknown[];
  embeds_meta: unknown[];
  mentions_meta: unknown;
}

export async function sendEventToRails(event: RailsEventPayload): Promise<{ id: number; status: string }> {
  const url = `${config.rails.base}/api/v1/discord/events`;
  const idempotencyKey = `discord.event.${event.snowflake_id}`;

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Internal-Token": config.rails.serviceToken,
      "Idempotency-Key": idempotencyKey,
    },
    body: JSON.stringify(event),
    signal: AbortSignal.timeout(10_000),
  });

  if (!res.ok) {
    const body = await res.text();
    logger.error("Rails event submission failed", { status: res.status, body });
    throw new Error(`Rails returned ${res.status}`);
  }

  return res.json() as Promise<{ id: number; status: string }>;
}