using Workerd = import "/workerd/workerd.capnp";

# Deno has `deno test`. workerd has `workerd test`, which runs exported tests.
const config :Workerd.Config = (
  services = [(name = "main", worker = .w)],
);

const w :Workerd.Worker = (
  compatibilityDate = "@DATE@",
  modules = [(name = "index.js", esModule = embed "index.js")],
);
