// 이벤트 핸들러 — Rails에서 처리되면 응답 송신은 DiscordOutboundJob이 처리
// 여기서는 워커 측 보조 작업 (typing 표시, ephemeral 응답 등)

import type { Message } from "discord.js";
import { logger } from "./logger.js";

export async function classifyAndDispatch(message: Message, _event: unknown): Promise<void> {
  // typing 표시 (사용자가 봇이 생각 중임을 알게 함)
  // PartialGroupDMChannel/StageChannel/VoiceChannel 등 sendTyping 미지원 타입은 좁히기
  try {
    if (
      message.channel.type !== 3 // GroupDM
    ) {
      await (message.channel as { sendTyping?: () => Promise<void> }).sendTyping?.();
    }
  } catch (err) {
    logger.warn("Typing indicator failed", { err: String(err) });
  }
  // 실제 응답은 Rails의 GenerateDiscordReplyJob → DiscordOutboundJob이 처리
  // (워커는 메시지 + Interaction을 받아 Rails로 송신만)
}