#!/usr/bin/env bash
set -e

DB_USER=postgres
DB_NAME=postgres
CONTAINER_NAME=deddiagdb


function import {
    FILE_NAME=$1
    TABLE_NAME=$2
    COMPRESSED=${3:-false}
    echo "Importing ${FILE_NAME} into ${TABLE_NAME}"

    if ${COMPRESSED}; then
      CAT_CMD="gzip -cd"
    else
      CAT_CMD="cat"
    fi

    ${CAT_CMD} ${FILE_NAME} | docker exec -i ${CONTAINER_NAME} psql -U ${DB_USER} -d ${DB_NAME} -c"COPY ${TABLE_NAME} from stdin CSV HEADER DELIMITER E'\t'"
}

CID=$(docker ps -q -f status=running -f name=^/${CONTAINER_NAME}$)
if [ ! "${CID}" ]; then
  echo "Error: Container ${CONTAINER_NAME} not running"; exit 1;
fi

cd "$(dirname "$0")"

echo "

██████╗ ███████╗██████╗ ██████╗ ██╗ █████╗  ██████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██║██╔══██╗██╔════╝
██║  ██║█████╗  ██║  ██║██║  ██║██║███████║██║  ███╗
██║  ██║██╔══╝  ██║  ██║██║  ██║██║██╔══██║██║   ██║
██████╔╝███████╗██████╔╝██████╔╝██║██║  ██║╚██████╔╝
╚═════╝ ╚══════╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝

a domestic electricity demand dataset of individual appliances in Germany

"

echo "> Importing DEDDIAG dataset to ${CONTAINER_NAME}"

echo "----------------------------------------"
echo "Creating Tables"
echo "----------------------------------------"
cat create_tables_0.sql | docker exec -i ${CONTAINER_NAME} psql -U ${DB_USER} -d ${DB_NAME}

echo "----------------------------------------"
echo "Importing Houses"
echo "----------------------------------------"
for x in $(ls house_*/house.tsv);
do
   import $x houses
done

echo "----------------------------------------"
echo "Importing Items"
echo "----------------------------------------"
for x in $(ls house_*/items.tsv);
do
   import $x items
done

echo "----------------------------------------"
echo "Importing Annotation Labels"
echo "----------------------------------------"
for x in $(ls house_*/item_*_annotation_labels.tsv);
do
   import $x annotation_labels
done

echo "----------------------------------------"
echo "Importing Annotations"
echo "----------------------------------------"
for x in $(ls house_*/item_*_annotations.tsv);
do
   import $x annotations
done

echo "----------------------------------------"
echo "Importing Measurements"
echo "----------------------------------------"
for x in $(ls house_*/item_*_data.tsv.gz);
do
   import $x measurements true
done

echo "----------------------------------------"
echo "Creating Indices, Views, Functions"
echo "----------------------------------------"
cat create_tables_1.sql | docker exec -i ${CONTAINER_NAME} psql -U ${DB_USER} -d ${DB_NAME}

echo "DONE"
