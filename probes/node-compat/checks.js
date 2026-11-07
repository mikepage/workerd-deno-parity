// Node built-in modules a Deno program can import with the node: prefix.
// Same file runs in workerd (with nodejs_compat) and Deno.
const modules = [
  "assert", "async_hooks", "buffer", "child_process", "console", "crypto", "diagnostics_channel",
  "dns", "events", "fs", "fs/promises", "http", "https", "module", "net", "os", "path",
  "perf_hooks", "process", "querystring", "readline", "stream", "stream/web", "string_decoder",
  "timers", "timers/promises", "tls", "url", "util", "v8", "vm", "worker_threads", "zlib", "sqlite",
];

export async function run() {
  const results = await Promise.allSettled(modules.map((m) => import(`node:${m}`)));
  const missing = modules.filter((_, i) => results[i].status === "rejected");
  // Importing a stub isn't using it: check a few calls that do real work.
  const calls = {};
  const tryCall = async (name, fn) => {
    try {
      calls[name] = (await fn()) === true;
    } catch {
      calls[name] = false;
    }
  };
  await tryCall("crypto.createHash", async () => {
    const { createHash } = await import("node:crypto");
    return createHash("sha256").update("a").digest("hex").startsWith("ca978112");
  });
  await tryCall("fs.writeFileSync /tmp", async () => {
    const fs = await import("node:fs");
    fs.writeFileSync("/tmp/probe.txt", "x");
    return fs.readFileSync("/tmp/probe.txt", "utf8") === "x";
  });
  await tryCall("zlib.gzipSync", async () => {
    const { gzipSync, gunzipSync } = await import("node:zlib");
    return gunzipSync(gzipSync("x")).toString() === "x";
  });
  await tryCall("Buffer global", async () => typeof globalThis.Buffer === "function");
  await tryCall("process.env", async () => typeof globalThis.process?.env === "object");
  const working = Object.values(calls).filter(Boolean).length;
  return {
    score: `${modules.length - missing.length}/${modules.length}`,
    calls: `${working}/${Object.keys(calls).length}`,
    missing,
    failedCalls: Object.keys(calls).filter((k) => !calls[k]),
  };
}
