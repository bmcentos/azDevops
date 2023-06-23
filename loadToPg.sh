#!/bin/bash
#########################################################################################
## Obj: O Objetivo desse script é fazer o load de um arquivo CSV para o banco Postgres
## By: Bruno Miquelini (bruno.santos@yaman.com.br)
########################################################################################
############# COLORS #############
     GREEN="\e[1;32m"
     DEFAULT="\e[0m"
     RED="\e[1;31m"
     YELLOW="\e[1;33m"
     BLUE="\e[1;36m"
     #Esse script visa tagear a pipeline e o projeto no sonar com base na variavel ProjectTag identificada no ReadMe.md do projeto
#Definições de variaveis
POC=$POC	#Se POC=true, o script subirá o banco docker local
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
TABLE_NAME=$TABLE_NAME
CSV_FILE=`ls *.csv`
CREATE_DB="CREATE DATABASE $DB_NAME;"
if [ "$opc" == "build" ] ; then
	echo -e "${BLUE}[+] Usando schema de Build${DEFAULT}"
export CREATE_TABLE_SQL="CREATE TABLE $TABLE_NAME (\
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
elif [ "$opc" == "release" ] ; then

	echo -e "${BLUE}[+] Usando schema de Release${DEFAULT}"
export CREATE_TABLE_SQL="CREATE TABLE $TABLE_NAME ( \
    projeto varchar, \
    release varchar, \
    release_definition varchar, \
    stage varchar, \
    trigger varchar, \
    data_criacao timestamp, \
    url varchar, \
    aprovacao varchar, \
    stage_status varchar, \
    stage_trigger varchar, \
    requested varchar, \
    tentativas int, \
    data_inicio timestamp, \
    data_fim timestamp, \
    duracao int \
);"
fi

LOAD_CSV_SQL="\copy $TABLE_NAME FROM $CSV_FILE DELIMITER ',' CSV HEADER;"

echo -e "${GREEN}[+] Usando o arquivo CSV: ${BLUE}$CSV_FILE${DEFAULT}"
#Verifica se o docker local esta em execução
if $POC && docker ps | grep postgres ; then
	echo -e "${YELLOW}[!!] Container alreary running!${DEFAULT}"
elif ! $POC ; then
	echo -e "${GREEN}[+] Conectando no banco ${BLUE}$DB_HOST:$DB_PORT!!!${DEFAULT}"
else
	echo -e "${GREEN}[+] Subindo container na porta localhost: $DB_PORT${DEFAULT}"
	docker run -d -v ./data:/var/lib/postgresql/data -e POSTGRES_USER=$DB_USER -e POSTGRES_PASSWORD=$DB_PASSWORD -p $DB_PORT:5432 postgres
	while  echo exit |nc -v localhost 5432
	  do
		echo -e "${YELLOW}Aguarde...${DEFAULT}"
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
echo -e "${GREEN}[+] Fazendo o Load do arquivo ${BLUE}$CSV_FILE ${GREEN}para o banco ${BLUE}$DB_NAME ${GREEN}e tabela ${BLUE}$TABLE_NAME${DEFAULT}"
if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$LOAD_CSV_SQL" ; then
	echo -e "${RED} Falha ao inserir os dados no banco!"
fi
echo -e "${GREEN}[+] Copiando o arquivo CSV, faça o bind no docker run para coleta do CSV: -v $(pwd):/app/csv/"
mkdir csv 2>/dev/null
cp -v $CSV_FILE /app/csv/$CSV_FILE 2> /dev/null
#Opcional: Fazendo o select no banco
echo | psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT * FROM $TABLE_NAME"
