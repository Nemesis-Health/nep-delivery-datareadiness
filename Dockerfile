FROM ghcr.io/nemesis-health/nep-r-base:4.3.3

WORKDIR /lep

COPY concepts_general.sql .
COPY run.R .

# Defaults overridden by CI via --env flags
ENV OMOP_DB_HOST=localhost
ENV OMOP_DB_PORT=5432
ENV OMOP_DB_NAME=omop
ENV OMOP_DB_USER=nep_ci
ENV OMOP_DB_PASS=""
ENV OMOP_CDM_SCHEMA=synpuf
ENV OUTPUT_DIR=/output

CMD ["Rscript", "run.R"]
