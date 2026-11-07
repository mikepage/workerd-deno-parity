// Deno's built-in storage: node:sqlite, file on disk.
import { DatabaseSync } from "node:sqlite";
const db = new DatabaseSync("/tmp/probe.db");
db.exec("CREATE TABLE IF NOT EXISTS t (v TEXT)");
db.prepare("INSERT INTO t VALUES (?)").run("ok");
console.log(db.prepare("SELECT v FROM t LIMIT 1").get().v);
