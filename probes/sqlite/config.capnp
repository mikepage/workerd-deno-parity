using Workerd = import "/workerd/workerd.capnp";

# Deno has Deno.KV and node:sqlite built in. workerd's answer: SQLite inside a
# Durable Object, stored on local disk.
const config :Workerd.Config = (
  services = [
    (name = "main", worker = .w),
    (name = "disk", disk = (path = "/tmp/probe-do", writable = true)),
  ],
  sockets = [(name = "http", address = "*:8080", http = (), service = "main")],
);

const w :Workerd.Worker = (
  compatibilityDate = "@DATE@",
  modules = [(name = "index.js", esModule = embed "index.js")],
  durableObjectNamespaces = [(className = "Db", uniqueKey = "probe-db", enableSql = true)],
  durableObjectStorage = (localDisk = "disk"),
  bindings = [(name = "DB", durableObjectNamespace = "Db")],
);
