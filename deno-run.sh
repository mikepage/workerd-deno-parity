#!/bin/sh
# The same probe files under Deno, for the reference column. Runs in denoland/deno.
set -u
cd "$(dirname "$0")"
mkdir -p results
out=results/deno-$(date +%Y%m%d-%H%M%S).tsv
v=$(deno --version | head -1 | cut -d' ' -f2)
printf "version\tprobe\tresult\tdetail\n" | tee "$out"

# Import a probe's default export and call its fetch handler, like a server would.
probe() {
  r=$(deno run -A --quiet - <<EOF 2>&1 | tail -1 | cut -c1-240
const m = await import("./probes/$1/$2");
const res = await m.default.fetch(new Request("http://localhost/"));
console.log(await res.text());
EOF
)
  case $r in ok*) printf "%s\t%s\tpass\t%s\n" "$v" "$1" "$(echo "${r#ok}" | sed 's/^ //')" ;; *) printf "%s\t%s\tfail\t%s\n" "$v" "$1" "$r" ;; esac | tee -a "$out"
}

probe hello index.js
probe ts-strip index.ts
probe jsx index.tsx
probe tla index.js
probe url-import index.js
probe npm-specifier index.js
probe web-apis index.js
probe node-compat index.js

# import.meta.main is only true in the entry module, so run that probe as the entry.
r=$(deno eval 'console.log(import.meta.main)' 2>&1)
printf "%s\timport-meta-main\t%s\timport.meta.main=%s\n" "$v" "$([ "$r" = true ] && echo pass || echo fail)" "$r" | tee -a "$out"
# Probes where Deno's API differs from workerd's: same feature, Deno's own spelling.
row() { printf "%s\t%s\t%s\t%s\n" "$v" "$1" "$2" "$3" | tee -a "$out"; }
r=$(deno run --quiet --no-prompt probes/deno/deny-net.js 2>&1 | tail -1)
[ "$r" = ok ] && row deny-net pass "no --allow-net" || row deny-net fail "$r"
r=$(deno run --allow-read --allow-write --quiet probes/deno/sqlite.js 2>&1 | tail -1)
[ "$r" = ok ] && row sqlite pass "node:sqlite" || row sqlite fail "$r"
deno run --help | grep -q -- '--watch' && row watch pass "deno run --watch" || row watch fail "no --watch"
deno test --quiet probes/deno/adds_test.js >/tmp/t.log 2>&1 && row test pass "deno test" || row test fail "$(tail -1 /tmp/t.log)"
if deno compile --quiet -o /tmp/hello probes/deno/sqlite.js >/tmp/c.log 2>&1 && [ -x /tmp/hello ]; then row compile pass "deno compile"; else row compile fail "$(tail -1 /tmp/c.log)"; fi
echo "wrote $out"
