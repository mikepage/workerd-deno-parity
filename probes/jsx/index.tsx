/** @jsx h */
// Deno transforms JSX in .tsx files. Type stripping alone can't.
const h = (tag: string) => tag;
const el = <p>hi</p>;
export default { fetch: () => new Response(el ? "ok" : "fail") };
