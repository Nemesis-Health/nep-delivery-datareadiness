FROM ghcr.io/nemesis-health/nep-r-base:4.3.3

WORKDIR /lep

COPY concepts_general.sql .
COPY run.R .

# Runtime output location default (DB config must be provided explicitly)
ENV OUTPUT_DIR=/output

CMD ["Rscript", "run.R"]
