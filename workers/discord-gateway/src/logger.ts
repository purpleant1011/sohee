// 구조화 로거 (실제 고객 데이터/인증 정보 로그 금지 — 원칙 4)

type Level = "debug" | "info" | "warn" | "error";

const REDACTED_KEYS = [
  "token",
  "password",
  "secret",
  "authorization",
  "api_key",
  "bot_token",
  "access_token",
  "refresh_token",
  "private_key",
];

function redact(obj: unknown): unknown {
  if (obj === null || typeof obj !== "object") return obj;
  if (Array.isArray(obj)) return obj.map(redact);
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (REDACTED_KEYS.some((rk) => k.toLowerCase().includes(rk))) {
      out[k] = "[REDACTED]";
    } else {
      out[k] = redact(v);
    }
  }
  return out;
}

function emit(level: Level, msg: string, meta: Record<string, unknown> = {}) {
  const line = JSON.stringify({
    t: new Date().toISOString(),
    level,
    service: "discord-gateway",
    msg,
    ...(redact(meta) as Record<string, unknown>),
  });
  if (level === "error") process.stderr.write(line + "\n");
  else process.stdout.write(line + "\n");
}

export const logger = {
  debug: (msg: string, meta?: Record<string, unknown>) => emit("debug", msg, meta),
  info: (msg: string, meta?: Record<string, unknown>) => emit("info", msg, meta),
  warn: (msg: string, meta?: Record<string, unknown>) => emit("warn", msg, meta),
  error: (msg: string, meta?: Record<string, unknown>) => emit("error", msg, meta),
};