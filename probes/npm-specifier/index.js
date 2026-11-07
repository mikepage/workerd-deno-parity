// Deno resolves npm: specifiers without node_modules.
import { Hono } from "npm:hono@4.6.0";
export default { fetch: () => new Response(typeof Hono === "function" ? "ok" : "fail") };
