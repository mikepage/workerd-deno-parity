// Deno sets import.meta.main in the entry module.
export default {
  fetch: () =>
    new Response(import.meta.main === true ? "ok" : `fail: import.meta.main is ${String(import.meta.main)}`),
};
