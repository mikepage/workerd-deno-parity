// Run without --allow-net: Deno must refuse the fetch.
try {
  await fetch("https://example.com/");
  console.log("fail: fetch allowed");
} catch (e) {
  console.log(e instanceof Deno.errors.NotCapable || e instanceof Deno.errors.PermissionDenied ? "ok" : `fail: ${e}`);
}
