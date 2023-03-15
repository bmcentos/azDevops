#!/bin/bash
######################################################################################
#       Objetivo: Listar metricas de pipeline de build de todos os projetos da org   #
#       Gerar arquivo CSV com o relatorio de build dos projetos                      #
######################################################################################
# By: Bruno Miquelini 

#Informe a organização
ORGANIZATION="ORG_NAME"
API_VERSION="6.0"
CSV=build.csv

#Condição para checar se o PAT foi definido
if [ -z $PAT ] ; then
        echo "[-] Necessario definir a variavel PAT com o token de autenticação com o Azure Devops"
        echo "  Use: export PAT=<token>"
        exit 1
fi

# Lista de projetos coletados do AzureDevops
projects=$(curl -s -u :$PAT "https://dev.azure.com/$ORGANIZATION/_apis/projects?api-version=$API_VERSION" | jq -r '.value[].name')

# Percorrendo projeto por projeto
IFS=$'\n'
for project in $projects
do
  echo "#########################################################################"
  echo "[+] Projeto: $project"
  # Converte o nome dos projetos para http string
  proj=`echo $project | sed -e 's/ /%20/g' -e 's/é/%C3%A9/g' -e 's/ã/%C3%A3/g' -e 's/â/%C3%A2/g' -e 's/õ/%C3%B5/g' -e 's/é/%C3%A9/g'`
  # Coleta as builds definitions por projeto
  builds=$(curl -s -u :$PAT "https://dev.azure.com/$ORGANIZATION/$proj/_apis/build/builds?api-version=$API_VERSION")
  IFS="
"
  # Percorre a lista de builds e coleta as informações do retorno do JSON via jq
  for row in $(echo "${builds}" | jq -r '.value[] | "\(.project.name),\(.definition.name),\(.startTime),\(.finishTime),\(.queueTime),\(.status),\(.reason),\(.sourceBranch),\(.result),\(._links.web.href)"' 2> /dev/null)
    do
      IFS=','
      # Recebe os valores retornados do jq para calculo de duração de build
      read -r proj_name build_name start_time finish_time queue_time status reason branch result url <<< "$row"
      duration=$(($(date -d "$finish_time" '+%s') - $(date -d "$start_time" '+%s')))
      Qduration=$(($(date -d "$start_time" '+%s') - $(date -d "$queue_time" '+%s')))
      # Caso a duração do build seja menor que 0, considera que ha necessidade de aprovação na pipeline
      if [ $duration -lt 0 ] ; then
        export duration="Aguardando aprovacao"
      fi
      IFS=
      # Printa na tela os dados retornados
      echo -e "  Proj: $proj_name\n, Build: $build_name\n, Inicio: $start_time\n, Tempo: $duration segundos\n, Tempo de espera: $Qduration segundos\n, Status: $status\n, Razão: $reason\n, Branch: $branch\n, Resultado: $result\n, URL: $url\n"
      # Gera o arquivo CSV
      echo "\"$proj_name\", \"$build_name\",$start_time, \"$duration\", \"$Qduration\", \"$status\", \"$reason\", \"$branch\", \"$result\", \"$url\"" >> $CSV
    done
    echo "#########################################################################"
  done
# Ordena arquivo CSV
sort $CSV
#Adiciona header no arquivo CSV
sed -i '1 i\\"Projeto\",\"Pipeline\",\"Resultado\",\"Tempo de espera\",\"Tempo de inicio\",\"Tempo final\",\"Status\",\"Razão\",\"Branch\"' $CSV
clear
echo "#####################################################################"
echo "[+] Coleta executada com sucesso!"
echo "#####################################################################"
echo "[+] Gerado o arquivo $CSV com `wc -l $CSV` linhas"
echo "#####################################################################"
