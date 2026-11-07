// Deno runs .ts files directly. Does workerd?
const answer: string = "ok";
export default { fetch: (): Response => new Response(answer) };
