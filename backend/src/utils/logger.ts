export const logger = {
  info: (msg: string, meta?: any) => {
    console.log(`[INFO] ${new Date().toISOString()} - ${msg}`, meta ? sanitizeMeta(meta) : '');
  },
  warn: (msg: string, meta?: any) => {
    console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`, meta ? sanitizeMeta(meta) : '');
  },
  error: (msg: string, err?: any) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`, err instanceof Error ? err.stack : err);
  },
};

function sanitizeMeta(meta: any): any {
  if (typeof meta !== 'object' || meta === null) return meta;
  const copy = { ...meta };
  const sensitiveKeys = ['password', 'token', 'authorization', 'bearer', 'secret'];
  for (const key of Object.keys(copy)) {
    if (sensitiveKeys.some((s) => key.toLowerCase().includes(s))) {
      copy[key] = '[REDACTED]';
    }
  }
  return copy;
}
