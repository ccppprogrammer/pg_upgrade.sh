#!/bin/bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

PGSQL_BIN="/usr/lib/postgresql"
PGSQL_CONFIG="/etc/postgresql"
PGSQL_DATA_DIRECTORY="/var/lib/postgresql"

function usage() {
	if [ -n "$1" ]; then
		echo "$1";
		echo ""
	fi
	echo "Usage: $0 [-n cluster-name]"
	echo "  -n, --cluster-name             PostgreSQL cluster name"
	echo "  -v, --source-version           Source PostgreSQL version"
	echo "  -V, --destination-version      Destination PostgreSQL version"
	echo "  -k, --data-checksums           Use checksums on data pages"
	echo "  -c, --check                    Check PostgreSQL clusters only, don't change any data"
	echo "  -h, -?, --help                 Display this help"
	echo ""
	echo "Example: $0 -n main -v 12 -V 13 -k -c"
	echo ""
	exit 1
}


if [[ "$#" -eq "0" ]]; then
	usage
fi

CMD="$0 $*"
while [[ "$#" -gt "0" ]]; do
	case $1 in
		-n|--cluster-name) CLUSTER_NAME="$2"; shift 2;;
		-v|--source-version) SOURCE_VERSION="$2"; shift 2;;
		-V|--destination-version) DESTINATION_VERSION="$2"; shift 2;;
		-c|--check) CHECK="--check"; shift;;
		-k|--data-checksums) DATA_CHECKSUMS="--data-checksums"; shift;;
		-\?|-h|--help) usage; shift 2;;
		*) usage "Unknown parameter passed: $1"; shift 2;;
	esac; 
done

if [[ "${SOURCE_VERSION}" == "" ]]; then
	echo "ERROR: PostgreSQL source version is not set."
	exit 1
fi

if [[ "${DESTINATION_VERSION}" == "" ]]; then
	echo "ERROR: PostgreSQL destination version is not set."
	exit 1
fi

if find "${PGSQL_DATA_DIRECTORY}/${DESTINATION_VERSION}/${CLUSTER_NAME}/" -mindepth 1 | read; then
	echo "WARNING: PostgreSQL data directory '${PGSQL_DATA_DIRECTORY}/${DESTINATION_VERSION}/${CLUSTER_NAME}/' is not empty."
	read -p "Continue (y/N)? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		echo "Exiting..."
		exit 1
	fi
else
	su postgres -c "${PGSQL_BIN}/${DESTINATION_VERSION}/bin/initdb ${DATA_CHECKSUMS} ${PGSQL_DATA_DIRECTORY}/${DESTINATION_VERSION}/${CLUSTER_NAME}"
	if [[ "$?" -ne 0 ]]; then
		echo "ERROR: initdb."
		exit 1
	fi
	su postgres -c "cp -v -f ${PGSQL_DATA_DIRECTORY}/${SOURCE_VERSION}/${CLUSTER_NAME}/postgresql.auto.conf ${PGSQL_DATA_DIRECTORY}/${DESTINATION_VERSION}/${CLUSTER_NAME}/"
fi

su postgres -c "date;
time ${PGSQL_BIN}/${DESTINATION_VERSION}/bin/pg_upgrade \
	${CHECK} --verbose \
	-j 19 \
	-k \
	-d ${PGSQL_DATA_DIRECTORY}/${SOURCE_VERSION}/${CLUSTER_NAME}/ \
	-D ${PGSQL_DATA_DIRECTORY}/${DESTINATION_VERSION}/${CLUSTER_NAME}/ \
	-b ${PGSQL_BIN}/${SOURCE_VERSION}/bin \
	-B ${PGSQL_BIN}/${DESTINATION_VERSION}/bin \
	-p 65440 \
	-P 65432 \
	--old-options '-c config_file=${PGSQL_CONFIG}/${SOURCE_VERSION}/${CLUSTER_NAME}/postgresql.conf' \
	--new-options '-c config_file=${PGSQL_CONFIG}/${DESTINATION_VERSION}/${CLUSTER_NAME}/postgresql.conf';
date;
"
