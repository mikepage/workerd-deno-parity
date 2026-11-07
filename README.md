# workerd-deno-parity

Is workerd, the open-source runtime under Cloudflare Workers, turning into Deno? This lab runs the same
feature probes against one workerd release per year since 2023 and against Deno 2.9.8.

## Conclusion

workerd matches Deno's APIs. It doesn't match Deno's module loading, and won't.

- **APIs: caught up.** 39/40 web APIs (only `BroadcastChannel` missing), 34/34 `node:` modules import, 5/5
  real Node calls work. Code written to web standards plus `node:` imports runs unchanged on both.
  Most of it is recent: `node:` went 16 → 28 in 2025 and 28 → 34 in 2026.
- **Module loading: by design, no.** URL imports, `npm:` specifiers and JSX fail in all five releases.
  workerd runs a fixed set of modules declared before it starts. Worker Loader, which loads code at runtime,
  takes finished JavaScript only.
- **TypeScript: partial and experimental.** Erasable types only, only for modules in `config.capnp`, only with
  `--experimental`. No enums, JSX or type checking. Deno runs full TypeScript and checks it.
  Cloudflare's `@cloudflare/worker-bundler` runs esbuild inside a Worker: a build step moved into the runtime.

What follows from it:

- Code known at deploy time: target workerd. With web APIs, `node:` and erasable TypeScript it runs on Deno too.
- Code that loads code it hasn't seen (plugins, user scripts, AI-written apps): Deno, or a bundler in front of
  Worker Loader.
- workerd's TypeScript support isn't for production while it needs `--experimental`.

| Feature | 2023-01 | 2023-10 | 2024-11 | 2025-11 | 2026-11 | Deno 2.9.8 |
|---|---|---|---|---|---|---|
| Run `.ts` files directly | – | – | – | **yes** ¹ | yes ¹ | yes |
| JSX in `.tsx` | – | – | – | – | – | yes |
| Top-level await | yes | yes | yes | yes | yes | yes |
| `import.meta.main` | – | – | **yes** ¹ | yes ¹ | yes ¹ | yes |
| Import from a URL | – | – | – | – | – | yes |
| `npm:` specifiers | – | – | – | – | – | yes |
| Built-in SQLite storage | – | – | **yes** ² | yes ² | yes ² | yes ³ |
| Deny network unless allowed | yes ⁴ | yes ⁴ | yes ⁴ | yes ⁴ | yes ⁴ | yes |
| Watch mode | yes | yes | yes | yes | yes | yes |
| Built-in test runner | – | **yes** | yes | yes | yes | yes |
| Compile to one binary | yes | yes | yes | yes | yes | yes |
| **Features passed** | **4/11** | **5/11** | **7/11** | **8/11** | **8/11** | **11/11** |
| Web APIs present | 27/40 | 32/40 | 37/40 | 39/40 | 39/40 | 40/40 |
| `node:` modules that import | 1/34 | 11/34 | 16/34 | 28/34 | **34/34** | 34/34 |
| Node calls that work ⁵ | 0/5 | 1/5 | 4/5 | 5/5 | 5/5 | 5/5 |
| Binary size | 65 MB | 89 MB | 130 MB | 116 MB | 155 MB | – |

1. Behind an experimental flag (`typescript_strip_types`, `new_module_registry`) and `--experimental`.
2. SQLite inside a Durable Object, stored on local disk (`enableSql`, `localDisk`).
3. `node:sqlite`. Deno KV also exists.
4. workerd's model differs: outbound `fetch()` goes to whatever service `globalOutbound` names. By default
   that's the internet, so it's opt-out, where Deno is opt-in.
5. `createHash`, `fs.writeFileSync` to `/tmp`, `gzipSync`, the `Buffer` global, `process.env`. A module
   that imports can still be a stub: `node:child_process` imports in workerd but can't spawn anything.

Raw results: [`results/workerd-20261107-150028.tsv`](results/workerd-20261107-150028.tsv) and
[`results/deno-20261107-150121.tsv`](results/deno-20261107-150121.tsv).

## What changed when

- **2023:** a test runner (`workerd test`). Node compat starts: `buffer`, `crypto`, `events`, `stream`,
  `util`, `async_hooks`.
- **2024:** SQLite in Durable Objects. `import.meta.main` through the new module registry (experimental).
  Web APIs catch up: `ReadableStream.from`, `EventSource`, `Promise.withResolvers`, `Array.fromAsync`.
- **2025:** TypeScript type stripping (experimental). Node jumps to 28/34: `fs`, `http`, `https`, `net`,
  `os`, `dns`, `tls`, `vm`.
- **2026:** the last six `node:` modules import, `node:sqlite` among them. The only web API still missing
  is `BroadcastChannel`.

## Lab

Every probe is a small worker in `probes/<name>/` with a `config.capnp`. `run.sh` fills in the
compatibility date of each release (workerd rejects dates past its build), starts `workerd serve`, and
passes the probe if `GET /` answers `ok`. A config error, an unknown flag or a missing module is a fail,
and the TSV records the first error line.

`web-apis` and `node-compat` share one `checks.js` between workerd and Deno, so their scores compare
directly. The rest of the Deno column runs the same `index.js` files, plus Deno's own spelling where the
API differs (`probes/deno/`: `deno test`, `deno compile`, `node:sqlite`, no `--allow-net`).

| Version | Date | Notes |
|---|---|---|
| v1.20230115.0 | 2023-01-16 | First release with an arm64 Linux binary. Links libc++ dynamically |
| v1.20231030.0 | 2023-10-31 | |
| v1.20241106.0 | 2024-11-06 | |
| v1.20251101.0 | 2025-11-01 | |
| v1.20261107.1 | 2026-11-07 | |

```bash
docker compose run --rm workerd   # all probes × all versions, ~1 min
docker compose run --rm deno      # the Deno column
VERSIONS=v1.20261107.1 PROBES="ts-strip sqlite" docker compose run --rm workerd
```

## Caveats

- One release per year. A feature that landed and was removed in between wouldn't show.
- A pass means the feature exists, not that it's equal. workerd's SQLite lives in a Durable Object;
  Deno's is a file. workerd's watch reloads the config; Deno's reloads the process.
- The `node:` score counts imports. Stubs import fine.
- The URL and `npm:` probes need network in the container. Deno had it; workerd fails before it tries.
