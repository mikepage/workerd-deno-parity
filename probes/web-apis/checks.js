// Web-standard APIs a Deno program can count on. Same file runs in workerd and Deno.
// Each check is a function so a missing global throws instead of breaking the module.
const checks = {
  fetch: () => typeof fetch === "function",
  Request: () => typeof Request === "function",
  Response: () => typeof Response === "function",
  "Response.json": () => typeof Response.json === "function",
  Headers: () => typeof Headers === "function",
  URL: () => typeof URL === "function",
  "URL.canParse": () => typeof URL.canParse === "function",
  URLSearchParams: () => typeof URLSearchParams === "function",
  URLPattern: () => typeof URLPattern === "function",
  "crypto.subtle": () => typeof crypto.subtle?.digest === "function",
  "crypto.randomUUID": () => typeof crypto.randomUUID === "function",
  structuredClone: () => typeof structuredClone === "function",
  CompressionStream: () => typeof CompressionStream === "function",
  DecompressionStream: () => typeof DecompressionStream === "function",
  TextEncoderStream: () => typeof TextEncoderStream === "function",
  TextDecoderStream: () => typeof TextDecoderStream === "function",
  "AbortSignal.timeout": () => typeof AbortSignal.timeout === "function",
  "AbortSignal.any": () => typeof AbortSignal.any === "function",
  EventTarget: () => typeof EventTarget === "function",
  CustomEvent: () => typeof CustomEvent === "function",
  Blob: () => typeof Blob === "function",
  File: () => typeof File === "function",
  FormData: () => typeof FormData === "function",
  ReadableStream: () => typeof ReadableStream === "function",
  "ReadableStream.from": () => typeof ReadableStream.from === "function",
  WritableStream: () => typeof WritableStream === "function",
  TransformStream: () => typeof TransformStream === "function",
  WebSocket: () => typeof WebSocket === "function",
  EventSource: () => typeof EventSource === "function",
  BroadcastChannel: () => typeof BroadcastChannel === "function",
  MessageChannel: () => typeof MessageChannel === "function",
  "performance.now": () => typeof performance?.now === "function",
  "navigator.userAgent": () => typeof navigator?.userAgent === "string",
  queueMicrotask: () => typeof queueMicrotask === "function",
  atob: () => typeof atob === "function",
  "Promise.withResolvers": () => typeof Promise.withResolvers === "function",
  "Array.fromAsync": () => typeof Array.fromAsync === "function",
  "Set.prototype.union": () => typeof new Set().union === "function",
  "Iterator.prototype.map": () => typeof globalThis.Iterator?.prototype?.map === "function",
  "Error.isError": () => typeof Error.isError === "function",
};

export function run() {
  const have = [];
  const missing = [];
  for (const [name, check] of Object.entries(checks)) {
    let ok = false;
    try {
      ok = check();
    } catch {}
    (ok ? have : missing).push(name);
  }
  return { score: `${have.length}/${have.length + missing.length}`, missing };
}
