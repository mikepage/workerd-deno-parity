// Top-level await in the main module.
const v = await Promise.resolve("ok");
export default { fetch: () => new Response(v) };
