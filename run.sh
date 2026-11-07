#!/bin/bash
# Run every probe against every workerd version in /opt/workerd. Writes results/workerd-<ts>.tsv.
# VERSIONS="v1.20261107.1" PROBES="ts-strip sqlite" ./run.sh  to narrow it down.
set -u
cd "$(dirname "$0")"
VERSIONS=${VERSIONS:-$(ls /opt/workerd)}
SERVE_PROBES="hello ts-strip jsx tla import-meta-main url-import npm-specifier web-apis node-compat sqlite deny-net"
PROBES=${PROBES:-"$SERVE_PROBES watch test compile"}
mkdir -p results
out=results/workerd-$(date +%Y%m%d-%H%M%S).tsv
printf "version\tprobe\tresult\tdetail\n" | tee "$out"

# Copy a probe to /tmp/run with the compatibility date filled in.
stage() {
  rm -rf /tmp/run /tmp/probe-do
  mkdir -p /tmp/run /tmp/probe-do
  cp -r "probes/$1/." /tmp/run/
  sed -i "s/@DATE@/$DATE/g" /tmp/run/*.capnp
}

# First error-looking line of the workerd log, flattened to one line.
first_error() {
  grep -m1 -iE 'error|failed|exception|unknown|no such|has no|not ' /tmp/run/log | tr '\t' ' ' | cut -c1-240
}

# Start a server command in /tmp/run, GET / once it answers, then stop it.
serve_and_get() {
  (cd /tmp/run && exec "$@") >/tmp/run/log 2>&1 &
  local pid=$! body=""
  for _ in $(seq 1 60); do
    sleep 0.25
    kill -0 $pid 2>/dev/null || break
    body=$(curl -s -m 10 localhost:8080/) && [ -n "$body" ] && break
  done
  kill $pid 2>/dev/null
  wait $pid 2>/dev/null
  if [[ $body == ok* ]]; then
    printf "pass\t%s" "$(echo "${body#ok}" | sed 's/^ //')"
  else
    local err
    err=$(first_error)
    printf "fail\t%s" "${err:-${body:-no response}}"
  fi
}

for v in $VERSIONS; do
  BIN=/opt/workerd/$v/workerd
  DATE=$(echo "$v" | sed -E 's/^v1\.([0-9]{4})([0-9]{2})([0-9]{2}).*/\1-\2-\3/')
  EXP=""
  "$BIN" serve --help 2>&1 | grep -q -- '--experimental' && EXP=--experimental
  for p in $PROBES; do
    case $p in
      watch)
        if "$BIN" serve --help 2>&1 | grep -q -- '--watch'; then r=$(printf "pass\tserve --watch"); else r=$(printf "fail\tno --watch flag"); fi ;;
      test)
        stage test
        if (cd /tmp/run && "$BIN" test $EXP config.capnp) >/tmp/run/log 2>&1 && grep -q PASS /tmp/run/log; then
          r=$(printf "pass\t%s" "$(grep -m1 PASS /tmp/run/log | tr '\t' ' ')")
        else r=$(printf "fail\t%s" "$(first_error || head -1 /tmp/run/log)"); fi ;;
      compile)
        stage hello
        if (cd /tmp/run && "$BIN" compile config.capnp > /tmp/run/app) 2>/tmp/run/log; then
          chmod +x /tmp/run/app
          r=$(serve_and_get ./app)
        else r=$(printf "fail\t%s" "$(first_error)"); fi ;;
      *)
        stage "$p"
        r=$(serve_and_get "$BIN" serve $EXP config.capnp) ;;
    esac
    printf "%s\t%s\t%s\n" "$v" "$p" "$r" | tee -a "$out"
  done
done
echo "wrote $out"
