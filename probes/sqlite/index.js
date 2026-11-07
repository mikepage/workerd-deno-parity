export class Db {
  constructor(state) {
    this.sql = state.storage.sql;
  }
  async fetch() {
    this.sql.exec("CREATE TABLE IF NOT EXISTS t (v TEXT)");
    this.sql.exec("INSERT INTO t VALUES (?)", "ok");
    const rows = [...this.sql.exec("SELECT v FROM t LIMIT 1")];
    return new Response(rows[0]?.v ?? "fail: no row");
  }
}

export default {
  fetch: (req, env) => env.DB.get(env.DB.idFromName("probe")).fetch(req),
};
