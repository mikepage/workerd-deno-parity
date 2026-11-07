using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [(name = "main", worker = .w)],
  sockets = [(name = "http", address = "*:8080", http = (), service = "main")],
);

const w :Workerd.Worker = (
  compatibilityDate = "@DATE@",
  compatibilityFlags = ["typescript_strip_types"],
  modules = [(name = "index.ts", esModule = embed "index.ts")],
);
