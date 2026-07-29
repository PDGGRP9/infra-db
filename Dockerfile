FROM postgres:16

COPY initdb/ /docker-entrypoint-initdb.d/

EXPOSE 5432