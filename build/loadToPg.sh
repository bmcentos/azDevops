#!/bin/bash
#########################################################################################
## Obj: O Objetivo desse script é fazer o load de um arquivo CSV para o banco Postgres
## By: Bruno Miquelini (bruno.santos@yaman.com.br)
########################################################################################

#Definições de variaveis
POC=$POC	#Se POC=true, o script subirá o banco docker local
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
TABLE_NAME=$TABLE_NAME
CSV_FILE="build.csv"
CREATE_DB="CREATE DATABASE $DB_NAME;"
CREATE_TABLE_SQL="CREATE TABLE $TABLE_NAME (\
  projeto VARCHAR(255), \
  pipeline VARCHAR(255), \
  data_de_inicio TIMESTAMP, \
  tempo_de_build INTEGER, \
  tempo_de_espera INTEGER, \
  status VARCHAR(255), \
  trigger VARCHAR(255), \
  branch VARCHAR(255), \
  resultado VARCHAR(255), \
  url VARCHAR(255), \
  tag_de_projeto VARCHAR(255) \
);
"
LOAD_CSV_SQL="\copy $TABLE_NAME FROM $CSV_FILE DELIMITER ',' CSV HEADER;"

#Verifica se o docker local esta em execução
if $POC && docker ps | grep postgres ; then
	echo "[!!] Container alreary running"
elif ! $POC ; then
	echo "[!!] Conectando no banco $DB_HOST:$DB_PORT!!!"
else
	echo "[+] Subindo container na porta localhost:$DB_PORT"
	docker run -d -v ./data:/var/lib/postgresql/data -e POSTGRES_USER=$DB_USER -e POSTGRES_PASSWORD=$DB_PASSWORD -p $DB_PORT:5432 postgres
	while  echo exit |nc -v localhost 5432
	  do
		echo Aguarde...
		sleep 2
	  done
fi
#Exportando a senha do HOST
export PGPASSWORD=$DB_PASSWORD 
#Criando banco de dados
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "$CREATE_DB"
#Dropando a tabela se existir
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE $TABLE_NAME"
#Criando a tabela
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$CREATE_TABLE_SQL"
#Fazendo o load do CSV para a tabela
echo "[+] Fazendo o Load do arquivo $CSV_FILE para o banco $DB_NAME e tabela $TABLE_NAME"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$LOAD_CSV_SQL"
#Opcional: Fazendo o select no banco
echo | psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT * FROM $TABLE_NAME"
