# pg_upgrade.sh
pg_upgrade wrapper to upgrade a PostgreSQL cluster to a new major version

## Usage
```
Usage: pg_upgrade.sh -n cluster-name -v source-version -V destination-version [-k] [-c]
  -n, --cluster-name             PostgreSQL cluster name
  -v, --source-version           Source PostgreSQL version
  -V, --destination-version      Destination PostgreSQL version
  -k, --data-checksums           Use checksums on data pages
  -c, --check                    Check PostgreSQL clusters only, don't change any data
  -h, -?, --help                 Display this help

Example: pg_upgrade.sh -n main -v 12 -V 13 -k -c
```
