#!/bin/bash
# Variaveis de cores
GREEN="\e[1;32m"
DEFAULT="\e[0m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
BLUE="\e[1;36m"

# Variaveis do Azure Devops
organization=$ORG
pat=$PAT

# Configuração para envio para o BQ DATASET
export SEND_TO_DATASET=true
export JSON=sonar.json
export DATASET_ID=az_devops_ci
export TABLE_ID=table-azure-images
export CSV=images.csv
export CSV_FILE=$CSV
export SCHEMA_FILE=$JSON
export PROJECT_ID=""
if [ -z $PROJECT_ID ] ;then
  echo "[-] Especifique o projeto GCP!"
  echo "  export PROJECT_ID=<gcp_project>
  exit 1
>$CSV

# Variaveis da checagem
check_file=Dockerfile
#Padrão artifact registry
org_registry='southamerica-east1-docker.pkg.dev
clear

# Verifica se variaveis necessarias foram informadas
if [ -z $pat ] || [ -z $organization ] ; then
        echo -e "${RED}[-] PAT ou ORG não informado. Por favor declarar envs:${DEFAULT}"
        echo "  export ORG=<org>"
        echo "  export PAT=<pat>"
        exit 1
fi

# Coleta nome de projetos
export clear_projects=$(curl -s -u ":$pat" "https://dev.azure.com/$organization/_apis/projects?api-version=6.0" | jq -r '.value[].name')
export projs=$(echo "$clear_projects" | wc -l)
# Converte o nome dos projetos para URL encode
export projects=$(printf '%s' "$clear_projects" | jq -s -R -r @uri)
#Ajusta IFS para coletar a lista de projetos correramente
IFS=$'\n' read -r -d '' -a projects <<< "$clear_projects"

# inicia contador em Zero
contador=0

# Inicia listagem de projetos
for project in "${projects[@]}"; do
        ((contador++))
        progresso=$((contador * 100 / $projs))
        n_project=$((n_project + 1))
        echo -e "${GREEN}[$n_project] Coletando do projeto: $project [${YELLOW}$progresso%${GREEN}]${DEFAULT}"
        # Coleta ID dos repositorios
        repositories=$(curl -s -u ":$pat" "https://dev.azure.com/$organization/$project/_apis/git/repositories?api-version=6.0" | jq -r '.value[].id' 2>/dev/null)
        # Percorre pelos repositorios
        for repositoryid in $repositories; do
                files=$(curl -s -u ":$pat" "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repositoryid/items?recursionlevel=full&api-version=6.0&scopepath=/" | jq -r '.value[].path' 2>/dev/null)
                repo_name=$(curl -s -u ":$pat" "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repositoryid" | jq .name 2>/dev/null)
                # Percorre pelos arquivos do projeto
                for file in $files; do
                        if [[ "$file" == **/"$check_file" ]] || [[ "$file" == "$check_file" ]]; then
                                echo -e "${YELLOW}\t\t- Repo Name: $repo_name"
                                echo -e "${GREEN}\t\t\t[+] $check_file encontrado: $file"
                                content=$(curl -s -u ":$pat" 'https://dev.azure.com/'$organization'/'$project'/_apis/git/repositories/'$repositoryid'/items?path='$file'&api-version=6.0')
                                # Coleta o valor de FROM ignorando padrões AS build ou AS install do nome da imagem
                                image=$(echo "$content" | grep -i ^from | grep -iv ^as| cut -d " " -f2| egrep -ivw 'install|build' )
                                if echo $image | grep "$org_registry" >/dev/null ; then
                                        echo -e "${GREEN}[+]\t\t\t Imagem no artifact Registry!"
                                        org_image=true
                                elif [ -z "$image" ] ; then
                                        export image=null
                                        org_image=false
                                else
                                        org_image=false
                                fi
                                if [ `echo $image | tr ' ' '\n' | wc -l` -gt 1 ] ;then
                                        echo -e "\t\t\t${GREEN}[+] Multistage Build!!!"
                                        export n_image=`echo $image | tr ' ' '\n' | wc -l`
                                        export image="$image;"
                                        export image=`echo $image | tr ' ' ';' | sed 's/;$//' `
                                        mult_stage=true
                                else
                                        export n_image=`echo $image | tr ' ' '\n' | wc -l`
                                        mult_stage=false
                                fi
                                echo -e "\t\t\t${GREEN}[+] Imagem base: ${BLUE}$image${DEFAULT}"
                                echo "\"$project\",$repo_name,\"$image\",$mult_stage",$org_image,$n_image >> $CSV
                        fi
                done
        done
done
# Verifica se será enviado para o dataset
if $SEND_TO_DATASET ; then
echo "[+] Creating BigQuery dataset"
else
  sed -i '1 i\\"Projeto\",\"Repositorio\",\"Imagens\",\"Is Multistage\",\"Is Registro interno\", \"Numero de imagens\""' $CSV
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
  if echo $i | grep Is 2> /dev/null ; then
    export default=BOOLEAN
  elif echo $i | grep 'Numero'  2> /dev/null ; then
    export default=INTEGER
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

 sed -i '1 i\\"Projeto\",\"Repositorio\",\"Imagens\",\"Is Multistage\",\"Is Registro interno\", \"Numero de imagens\""' $CSV
