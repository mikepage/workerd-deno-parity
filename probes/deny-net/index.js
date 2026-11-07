export default {
  async fetch() {
    const res = await fetch("https://example.com/");
    const body = await res.text();
    return new Response(res.status === 403 && body === "denied" ? "ok" : `fail: ${res.status}`);
  },
};
