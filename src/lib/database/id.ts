export function createLocalId(prefix: string): string {
  const timePart = Date.now().toString(36);
  const randomPart = Math.random().toString(36).slice(2, 10);

  return `${prefix}_${timePart}_${randomPart}`;
}

export function createIsoTimestamp(date = new Date()): string {
  return date.toISOString();
}
