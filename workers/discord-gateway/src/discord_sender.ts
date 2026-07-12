// discord_sender.ts — Rails → 워커 송신 채널
// POST /send { channel_id, content, reply_to?, card? } 받아 discord.js channel.send() 호출
// 인증: X-Internal-Token (DISCORD_GATEWAY_SERVICE_TOKEN과 동일)

import type { Client } from "discord.js";
import { config } from "./config.js";
import { logger } from "./logger.js";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";

interface SendPayload {
  channel_id: string;
  content?: string;
  reply_to?: string | null;
  card?: {
    title?: string;
    description?: string;
    quote?: string;
    actions?: Array<{ label: string; style: "primary" | "secondary" | "danger"; action: string; proposal_id: number }>;
    expires_at?: string;
  } | null;
}

export class DiscordSender {
  constructor(private readonly client: Client) {}

  start(port: number = 7300): void {
    const server = createServer((req, res) => this.handle(req, res));
    server.listen(port, "0.0.0.0", () => {
      logger.info(`discord-sender HTTP server listening on :${port}`);
    });
  }

  private async handle(req: IncomingMessage, res: ServerResponse): Promise<void> {
    // 라우트 분기: GET /health, POST /send 만 허용
    const method = req.method ?? "GET";
    if (method === "GET" && req.url === "/health") {
      this.handleHealth(res);
      return;
    }
    if (method !== "POST" || req.url !== "/send") {
      res.statusCode = 404;
      res.end("not_found");
      return;
    }
    await this.handleSend(req, res);
  }

  private handleHealth(res: ServerResponse): void {
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({
      ok: true,
      discord_ready: this.client.isReady(),
      bot_user: this.client.user?.tag ?? null,
      uptime_seconds: Math.round(process.uptime()),
    }));
  }

  private async handleSend(req: IncomingMessage, res: ServerResponse): Promise<void> {

    // /send — 인증
    const provided = (req.headers["x-internal-token"] ?? "").toString();
    if (!config.rails.serviceToken || !provided || provided !== config.rails.serviceToken) {
      logger.warn("discord-sender rejected (bad token)", { provided: provided ? "[present]" : "[missing]" });
      res.statusCode = 401;
      res.end("unauthorized");
      return;
    }

    // body 읽기
    const chunks: Buffer[] = [];
    for await (const chunk of req) chunks.push(chunk as Buffer);
    const raw = Buffer.concat(chunks).toString("utf8");
    let payload: SendPayload;
    try {
      payload = JSON.parse(raw) as SendPayload;
    } catch {
      res.statusCode = 400;
      res.end("invalid_json");
      return;
    }

    if (!payload.channel_id) {
      res.statusCode = 400;
      res.end("missing_channel_id");
      return;
    }
    if (!payload.content && !payload.card) {
      res.statusCode = 400;
      res.end("missing_content_or_card");
      return;
    }

    try {
      const sent = await this.send(payload);
      logger.info("discord-sender sent", { channel_id: payload.channel_id, message_id: sent.id, has_card: Boolean(payload.card) });
      res.setHeader("Content-Type", "application/json");
      res.end(JSON.stringify({ ok: true, message_id: sent.id, sent_at: new Date().toISOString() }));
    } catch (err) {
      logger.error("discord-sender failed", { err: String(err), channel_id: payload.channel_id });
      res.statusCode = 502;
      res.setHeader("Content-Type", "application/json");
      res.end(JSON.stringify({ ok: false, error: String(err) }));
    }
  }

  private async send(payload: SendPayload): Promise<{ id: string }> {
    const channel = await this.client.channels.fetch(payload.channel_id);
    if (!channel) throw new Error("channel_not_found");
    if (!("send" in channel) || typeof (channel as { send?: unknown }).send !== "function") {
      throw new Error("channel_not_text_writable");
    }
    const textChannel = channel as { send: (opts: unknown) => Promise<{ id: string }> };

    if (payload.card) {
      // Embed + 버튼 카드 (MVP: embed만, 버튼은 Interactions 라우트와 연결될 때 활성화)
      const embed = {
        title: payload.card.title ?? "(no title)",
        description: payload.card.description ?? "",
        fields: payload.card.quote ? [{ name: "요청 발화", value: `> ${payload.card.quote}` }] : [],
        timestamp: payload.card.expires_at ?? new Date().toISOString(),
        footer: { text: "소희 — 변경 제안" },
      };
      const messageOpts = { embeds: [embed] };
      const msg = await textChannel.send(messageOpts);
      return { id: msg.id };
    }

    // 일반 텍스트 응답
    const messageOpts: { content: string; reply?: { messageReference: string } } = {
      content: payload.content ?? "",
    };
    if (payload.reply_to) {
      messageOpts.reply = { messageReference: payload.reply_to };
    }
    const msg = await textChannel.send(messageOpts);
    return { id: msg.id };
  }
}
