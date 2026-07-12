// Discord Gateway entrypoint (P1 skeleton, 2026-07-12)
// 역할: discord.js 클라이언트, 이벤트 라우팅, 권한 가드, Rails 내부 API 송신
// 사람 단계: DISCORD_BOT_TOKEN 필요 (.env)

import { Client, GatewayIntentBits, Events } from "discord.js";
import { config } from "./config.js";
import { logger } from "./logger.js";
import { sendEventToRails } from "./rails_client.js";
import { classifyAndDispatch } from "./event_handler.js";
import { PermissionGuard } from "./permission_guard.js";

const requiredIntents: GatewayIntentBits[] = [
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages,
  GatewayIntentBits.MessageContent, // Privileged — 사람 단계 #3에서 활성화
  GatewayIntentBits.GuildMembers,
];

async function main() {
  if (!config.discord.botToken) {
    logger.error("DISCORD_BOT_TOKEN not set — 사람 단계 #2에서 발급 후 .env에 등록");
    process.exit(1);
  }

  const client = new Client({
    intents: requiredIntents,
    presence: { status: "online", activities: [{ name: "소희 — 대화 중" }] },
  });

  const guard = new PermissionGuard();

  client.once(Events.ClientReady, (c) => {
    logger.info(`Logged in as ${c.user.tag} (${c.user.id})`);
  });

  client.on(Events.MessageCreate, async (message) => {
    if (message.author.bot) return;
    if (!guard.canReceive(message)) return;

    const eventPayload = {
      snowflake_id: message.id,
      guild_id: message.guildId,
      channel_id: message.channelId,
      author_discord_id: message.author.id,
      kind: "message_create",
      content_raw: message.content,
      attachments_meta: Array.from(message.attachments.values()).map((a) => ({
        id: a.id,
        filename: a.name,
        url: a.url,
        size: a.size,
        contentType: a.contentType,
      })),
      embeds_meta: message.embeds.map((e) => e.toJSON()),
      mentions_meta: {
        users: Array.from(message.mentions.users.keys()),
        roles: Array.from(message.mentions.roles.keys()),
        channels: Array.from(message.mentions.channels.keys()),
      },
    };

    try {
      await sendEventToRails(eventPayload);
      await classifyAndDispatch(message, eventPayload);
    } catch (err) {
      logger.error("Message handling failed", { err, messageId: message.id });
    }
  });

  client.on(Events.InteractionCreate, async (interaction) => {
    if (!interaction.isButton() && !interaction.isModalSubmit()) return;
    // 버튼/모달 응답은 Rails가 Interaction endpoint로 수신 (별도 라우트)
    logger.info("Interaction received — forwarded to Rails interaction endpoint", {
      id: interaction.id,
      type: interaction.type,
    });
  });

  await client.login(config.discord.botToken);
}

main().catch((err) => {
  logger.error("Fatal", { err });
  process.exit(1);
});