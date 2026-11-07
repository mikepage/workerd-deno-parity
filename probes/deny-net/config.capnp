using Workerd = import "/workerd/workerd.capnp";

# Deno denies network access unless you pass --allow-net. workerd's version:
# route the worker's outbound fetch() to a service of your choice.
const config :Workerd.Config = (
  services = [
    (name = "main", worker = .w),
    (name = "deny", worker = .deny),
  ],
  sockets = [(name = "http", address = "*:8080", http = (), service = "main")],
);

const w :Workerd.Worker = (
  compatibilityDate = "@DATE@",
  modules = [(name = "index.js", esModule = embed "index.js")],
  globalOutbound = "deny",
);

const deny :Workerd.Worker = (
  compatibilityDate = "@DATE@",
  modules = [(name = "deny.js", esModule = embed "deny.js")],
);
