import { run } from "./checks.js";
export default { fetch: async () => new Response("ok " + JSON.stringify(await run())) };
