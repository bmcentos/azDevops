#!/bin/bash
######################################################################################
#       Objetivo: Listar metricas de pipeline de build de todos os projetos da org   #
#       Gerar arquivo CSV com o relatorio de build dos projetos                      #
######################################################################################
# By: Bruno Miquelini (bruno.miquelini@msn.com)

ORGANIZATION=""
API_VERSION="6.0"
CSV=build.csv
# Habilita criação/Load do CSV para o dataset
SEND_TO_DATASET=true
export JSON=build.json
export DATASET_ID=az_devops_ci
export TABLE_ID=table-azure-ci
export CSV_FILE=$CSV
export SCHEMA_FILE=build.json
export PROJECT_ID=

#INICIO
clear
>$CSV
#Condição para checar se o PAT foi definido
if [ -z $PAT ] ; then
        echo "[-] Necessario definir a variavel PAT com o token de autenticação com o Azure Devops"
        echo "  Use: export PAT=<token>"
        exit 1
fi

# Lista de projetos coletados do AzureDevops
projects=$(curl -s -u :$PAT "https://dev.azure.com/$ORGANIZATION/_apis/projects?api-version=$API_VERSION" | jq -r '.value[].name')

echo "################### INICIO ################################"
# Percorrendo projeto por projeto
IFS=$'\n'
for project in $projects
do
        echo $project
        ano=`date +%Y`
        count_ano=2019
        while [ $count_ano -lt $ano ]
             do
                echo $count_ano
                inicio="$count_ano-01-01T00:00:00Z"
                count_ano=$(( count_ano + 1 ))
                fim="$count_ano-01-01T00:00:00Z"

                  echo "#########################################################################"
                  echo "[+] Projeto: $project - $count_ano"
                  proj=`echo $project | sed -e 's/ /%20/g' -e 's/é/%C3%A9/g' -e 's/ã/%C3%A3/g' -e 's/â/%C3%A2/g' -e 's/õ/%C3%B5/g' -e 's/é/%C3%A9/g'`
                  builds=$(curl -s -u :$PAT 'https://dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/build/builds?api-version='$API_VERSION'&minTime='$inicio'&maxTime='$fim'&$top=5000')
                  echo "#########################################################################"
                  echo "[+] Projeto: $project"
  IFS="
"
  # Percorre a lista de builds e coleta as informações do retorno do JSON via jq
  for row in $(echo "${builds}" | jq -r '.value[] | "\(.project.name),\(.definition.name),\(.startTime),\(.finishTime),\(.queueTime),\(.status),\(.reason),\(.sourceBranch),\(.result),\(._links.web.href),\(.tags[0])"' 2> /dev/null)
    do
      IFS=','
      # Recebe os valores retornados do jq para calculo de duração de build
      read -r proj_name build_name start_time finish_time queue_time status reason branch result url tag <<< "$row"
      duration=$((`date -d "$finish_time" '+%s'` - `date -d "$start_time" '+%s'`))
      Qduration=$((`date -d "$start_time" '+%s'` - `date -d "$queue_time" '+%s'`))
      #Converte para timestamp
      start_time=`date --date=''$start_time'' '+%Y-%m-%d %H:%M:%S'`
      # Caso a duração do build seja menor que 0, considera que ha necessidade de aprovação na pipeline
      if [ $duration -lt 0 ] ; then
        export duration="9999"
      fi
      IFS=
      # Printa na tela os dados retornados
      echo "..."
      echo -e "  Proj: $proj_name\n Build: $build_name\n Inicio: $start_time\n Tempo: $duration segundos\n Tempo de espera: $Qduration segundos\n Status: $status\n Razão: $reason\n Branch: $branch\n Resultado: $result\n URL: $url\n TAG Projeto: $tag"
      # Gera o arquivo CSV
      echo "\"$proj_name\", \"$build_name\", \"$start_time\", \"$duration\", \"$Qduration\", \"$status\", \"$reason\", \"$branch\", \"$result\", \"$url\", \"$tag\"" >> $CSV
    done
    echo "#########################################################################"
  done
done
# Ordena arquivo CSV
sort $CSV > $CSV-old
mv -v $CSV-old $CSV
#Adiciona header no arquivo CSV
sed -i '1 i\\"Projeto\", \"Pipeline\", \"Data de Inicio\", \"Tempo de build\", \"Tempo de espera\", \"Status\", \"Trigger\",\"Branch\",\"Resultado\", \"URL\", "TAG de projeto"' $CSV
clear
echo "#####################################################################"
echo "[+] Coleta executada com sucesso!"
echo "#####################################################################"
echo "[+] Gerado o arquivo $CSV com `wc -l $CSV` linhas"
echo "#####################################################################"

# Verifica se será enviado para o dataset
if $SEND_TO_DATASET ; then
echo "[+] Creating BigQuery dataset"
else
  exit 0

fi

echo "[!!] Usando informações do projeto: "
cat $0 | egrep '^CSV|JSON=|DATASET_ID=|TABLE_ID=|PROJECT_ID='| cut -d "=" -f2 | sed -e '1 i[+] CSV: ' -e '2 i\\n[+] SCHEMA: ' -e '3 i\\n[+] DATASET: ' -e '4 i\\n[+] TABELA:' -e '5 i\\n[+] PROJETO:'
gcpAccount=`gcloud auth list 2> /dev/null| grep "^*" | tr -d ' *'`
if [ -f $gcpAccount ] ; then
  echo "  [-] Nenhum usuario autenticado. Considere fazer a autenticação do agente no GCP!"
  exit 1
else
  echo "  [+] Usando conta GCP: $gcpAccount"
fi

# Montando o schema json para criação do dataset
echo "[+] Montando schema da tabela..."
>$JSON
IFS=$'\n'
echo '[' >>$JSON
# Coleta header do CSV
for i in `head -1 $CSV | tr ',' '\n' | sed 's/^ //' | tr -d '"'| tr ' ' '_'`; do
  default=STRING
  # Faz o tratamento de tipo de dados
  if echo $i | grep Data 2> /dev/null ; then
    export default=TIMESTAMP
  elif echo $i | grep Tempo 2> /dev/null ; then
    export default=NUMERIC
  fi
  echo '    {
    "mode": "NULLABLE",
    "name": "'$i'",
    "type": "'$default'"
              },' >> $JSON
      done
echo ']' >>$JSON
echo "JSOSchema"
line=`wc -l $JSON | cut -d " " -f1`
line=$(( line - 1 ))
echo $line
sed -i ''$line', $ d' $JSON
echo -e "\t}\n]" >> $JSON
echo
echo "[+] Verificando se dataset $DATASET_ID ja existe..."
if bq ls | grep $DATASET_ID ; then
  echo "Dataset ja existe: $DATASET_ID"
else
  echo "  - Creating schema"
  bq mk \
  --project_id=$PROJECT_ID \
  --schema=$SCHEMA_FILE \
  $DATASET_ID.$TABLE_ID
fi

echo "[+] Fazendo o Load do arquivo $CSV para o dataset $DATASET_ID"
# Remove header do arquivo CSV para fazer o load para o BigQuery
sed -i '1 d' $CSV
#Faz o load do CSV sobrescrevendo os dados atuais
bq load \
  --project_id=$PROJECT_ID \
  --source_format=CSV \
  --replace=true \
$DATASET_ID.$TABLE_ID \
$CSV_FILE
out="$?"
if [ $? -eq 0 ] ; then
  echo "##############################################################################"
  echo "Fim da execução - Sucesso"
else
  echo "##############################################################################"
  echo "Fim da execução - Falha - STDERR $out"
fi
sed -i '1 i\\"Projeto\", \"Pipeline\", \"Data de Inicio\", \"Tempo de build\", \"Tempo de espera\", \"Status\", \"Trigger\",\"Branch\",\"Resultado\", \"URL\", "TAG de projeto"' $CSV
