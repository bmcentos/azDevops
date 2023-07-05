#!/bin/bash

# Configuração para envio para o BQ DATASET
SEND_TO_DATASET=true
export JSON=sonar.json
export DATASET_ID=az_devops_sonar
export TABLE_ID=table-azure-sonar
export CSV=sonar_metrics.csv
export CSV_FILE=$CSV
export SCHEMA_FILE=$JSON
export PROJECT_ID=$PROJECT_ID

# Autenticação do SONAR
export SONARCLOUD_API_TOKEN=$SONARCLOUD_API_TOKEN
if [ -z $SONARCLOUD_API_TOKEN ] ; then
        clear
        echo -e "\n\n################################################################################################"
        echo "[-] Por favor, adicione a variavel SONARCLOUD_API_TOKEN para autenticar na API!"
        echo "          export SONARCLOUD_API_TOKEN=<token>"
        echo "################################################################################################"
        exit 1
fi

SONARCLOUD_ORGANIZATION=$SONARCLOUD_ORGANIZATION
if [ -z $SONARCLOUD_ORGANIZATION ] ; then
  echo "[-] Por favor, defina a variavel SONARCLOUD_ORGANIZATION"
  echo "  export SONARCLOUD_ORGANIZATION=<org>"
fi

if [ "$SEND_TO_DATASET" == "true" ] && [ -z $PROJECT_ID ] ; then
  echo "[-] Por favor, defina o PROJECT_ID do projeto GCP para envio das metricas..."
  echo "  export PROJECT_ID=<project>"
fi

# Endipoint de projetos
API_ENDPOINT="https://sonarcloud.io/api/components/search_projects"

# Parametros para coleta de informações dos projetos
API_PARAMS="organization=$SONARCLOUD_ORGANIZATION&boostNewProjects=true&p=1&ps=500&&facets=reliability_rating,security_rating,security_review_rating,sqale_rating,coverage,duplicated_lines_density,ncloc,alert_status,languages,tags"
response=$(curl -s -u "$SONARCLOUD_API_TOKEN:" "$API_ENDPOINT?$API_PARAMS")
projs=$(echo $response | jq .components[].key | wc -l)
#Tempo de inicio da execução
start_time=$(date +%s)

if [[ $? -eq 0 ]]; then
  # Extrai as informações dos projetos do JSON de resposta
  projects=$(echo "$response" | jq -r '.components[] | [.name, .key] | @csv' | sed 's/"//g')
  echo "\"Cobertura_percent\",\"Projeto\",\"Security_Hotspot_Reviewed_percent\",\"Classes\",\"Code_Smells\",\"Bugs\",\"Reliability_Rating\",\"Security_Rating\",\"Security_Review_Rating\",\"Sqale_Rating\",\"Duplicated_Lines_Density\",\"Alert_Status\",\"Tags\",\"Analysis_Date\"" > $CSV
  #Inicia contagem para coleta de status de progresso
  contador=0
  while IFS= read -r project; do
    ((contador++))
    progresso=$((contador * 100 / $projs))

    n_project=$((n_project + 1))
    project_name=$(echo "$project" | cut -d',' -f1)
    project_key=$(echo "$project" | cut -d',' -f2)
    echo -e "[$n_project] Coletando do projeto: $project_key\t[$progresso%]"
    analysis_date=$(echo "$response" | jq -r '.components[] | "\(.key);\(.analysisDateAllBranches)"' | grep $project_key | cut -d ";" -f2 | tr -d '\n' )
    if [ -z $analysis_date ] || [ "$analysis_date" == null ] ; then
            analysis_date='2020-01-01T00:00:00+0200'
    elif [ `echo $analysis_date | wc -c` -gt 25 ] ; then
            analysis_date=`echo $analysis_date | cut -c -24`
    fi
    # Converte data para timestamp
    analysis_date=$(date -d "$analysis_date" +%s)
    metrics_api_endpoint="https://sonarcloud.io/api/measures/component"
    #Metricas que serão coletadas
    metrics_api_params="component=$project_key&metricKeys=coverage,security_hotspots_reviewed,classes,code_smells,bugs,reliability_rating,security_rating,security_review_rating,sqale_rating,duplicated_lines_density,alert_status,tags&f=analysisDate,leakPeriodDate"
    metrics_response=$(curl -s -u "$SONARCLOUD_API_TOKEN:" "$metrics_api_endpoint?$metrics_api_params")
    coverage=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "coverage") | .value')
    if [ -z $coverage ] ; then
            coverage=0.0
    fi
    hotspot_reviewed=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "security_hotspots_reviewed") | .value')
    if [ -z $hotspot_reviewed ] ; then
            hotspot_reviewed=0
    fi
    classes=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "classes") | .value')
    if [ -z $classes ] ; then
            classes=0
    fi
    code_smells=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "code_smells") | .value')
    if [ -z $code_smells ] ; then
            code_smells=0
    fi
    bugs=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "bugs") | .value')
    if [ -z $bugs ] ; then
            bugs=0
    fi
    reliability_rating=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "reliability_rating") | .value')
    if [ -z $reliability_rating ] ; then
            reliability_rating=0
    fi
    security_rating=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "security_rating") | .value')
    if [ -z $security_rating ] ; then
            security_rating=0
    fi
    security_review_rating=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "security_review_rating") | .value')
    if [ -z $security_review_rating ] ; then
            security_review_rating=0
    fi
    sqale_rating=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "sqale_rating") | .value')
    if [ -z $sqale_rating ] ; then
            sqale_rating=0
    fi

    duplicated_lines_density=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "duplicated_lines_density") | .value')
    if [ -z $duplicated_lines_density ] ; then
            duplicated_lines_density=0
    fi
    alert_status=$(echo "$metrics_response" | jq -r '.component.measures[] | select(.metric == "alert_status") | .value')
    if [ -z $alert_status ] ; then
            alert_status=none
    fi
    tags=$(curl -s -u "$SONARCLOUD_API_TOKEN:" -X GET 'https://sonarcloud.io/api/components/show?component='$project_key'' | jq -r '.component.tags[]' | tr '\n' ':' |sed 's/:$//')
    if [ -z $tags ] ; then
            tags=null
    fi
    echo $tags
    csv_line="$coverage,\"$project_name\",$hotspot_reviewed,$classes,$code_smells,$bugs,$reliability_rating,$security_rating,$security_review_rating,$sqale_rating,$duplicated_lines_density,\"$alert_status\",\"$tags\",$analysis_date"

    echo "$csv_line" >> $CSV
    end_time=$(date +%s)
    exec_time=$((end_time - start_time))
    echo "    [+] $exec_time Segundos de execução..."

  done <<< "$projects"
  end_time=$(date +%s)
  exec_time=$((end_time - start_time))
  echo "[+++] Gerado o arquivo $CSV com sucesso!"
  echo "  Tempo de execução: $exec_time segundos (`expr $exec_time / 60` Minutos)"
else
  end_time=$(date +%s)
  exec_time=$((end_time - start_time))
  echo "[-] Falha em coletar metricas da ORG $SONARCLOUD_ORGANIZATION!"
  echo "  Verifique o SONARCLOUD_API_TOKEN!"
fi

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
  default=FLOAT
  # Faz o tratamento de tipo de dados
  if echo $i | grep Date 2> /dev/null ; then
    export default=TIMESTAMP
  elif echo $i | egrep -i 'Projeto|Status|Tags'  2> /dev/null ; then
    export default=STRING
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
  echo "  - Creating schema"
  bq mk \
  --project_id=$PROJECT_ID \
  --schema=$SCHEMA_FILE \
  $DATASET_ID.$TABLE_ID

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
