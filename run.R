library(DatabaseConnector)
library(SqlRender)

# ── Connection parameters from environment ────────────────────────────────────
db_host   <- Sys.getenv("OMOP_DB_HOST",   "localhost")
db_port   <- as.integer(Sys.getenv("OMOP_DB_PORT", "5432"))
db_name   <- Sys.getenv("OMOP_DB_NAME",   "omop")
db_user   <- Sys.getenv("OMOP_DB_USER",   "nep_ci")
db_pass   <- Sys.getenv("OMOP_DB_PASS",   "")
cdm_schema <- Sys.getenv("OMOP_CDM_SCHEMA", "synpuf")

output_dir <- Sys.getenv("OUTPUT_DIR", "/output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Download JDBC driver if not already present ───────────────────────────────
jdbc_dir <- "/jdbc"
dir.create(jdbc_dir, showWarnings = FALSE, recursive = TRUE)
if (length(list.files(jdbc_dir, pattern = "\\.jar$")) == 0) {
  message("JDBC driver not found in /jdbc, downloading...")
  DatabaseConnector::downloadJdbcDrivers("postgresql", pathToDriver = jdbc_dir)
} else {
  message("Using pre-installed JDBC driver from /jdbc")
}

sql_file <- "concepts_general.sql"

# ── Connect ───────────────────────────────────────────────────────────────────
connectionDetails <- createConnectionDetails(
  dbms     = "postgresql",
  server   = paste0(db_host, "/", db_name),
  user     = db_user,
  password = db_pass,
  port     = db_port,
  pathToDriver = jdbc_dir
)
con <- connect(connectionDetails)

# Ensure DROP TABLE only targets temp tables, not permanent ones
renderTranslateExecuteSql(con, "SET search_path TO pg_temp, public")

# ── Build schema prefix ───────────────────────────────────────────────────────
schema <- cdm_schema
if (nchar(schema) > 0 && !endsWith(schema, "."))
  schema <- paste0(schema, ".")

# ── Read and execute SQL ──────────────────────────────────────────────────────
s <- readr::read_file(sql_file)
s <- gsub("@cdm_schema.", schema, s)
# Qualify the concepts DROP to pg_temp to avoid touching any permanent table
s <- gsub("(?i)drop\\s+table\\s+if\\s+exists\\s+concepts\\b",
          "drop table if exists pg_temp.concepts", s, perl = TRUE)

statements <- strsplit(s, ";")[[1]]
n <- length(statements)
if (n > 0 && trimws(statements[n]) == "") n <- n - 1

for (i in 1:(n - 1)) {
  renderTranslateExecuteSql(con, trimws(statements[i], "l"))
}

res <- renderTranslateQuerySql(con, trimws(statements[n], "l"))

# ── Write output ──────────────────────────────────────────────────────────────
output_file <- file.path(output_dir, "concepts_general.csv")
write.csv(res, output_file, row.names = FALSE)
message(output_file, " written (", nrow(res), " rows).")
