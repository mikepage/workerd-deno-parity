// Deno imports modules straight from a URL.
import { Hono } from "https://esm.sh/hono@4.6.0";
export default { fetch: () => new Response(typeof Hono === "function" ? "ok" : "fail") };
