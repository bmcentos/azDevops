#!/bin/bash
######################################################################################
#	Objetivo: Listar metricas de pipeline de build de todos os projetos da org   #
#	Gerar arquivo CSV com o relatorio de build dos projetos			     #
######################################################################################
# By: Bruno Miquelini (bruno.santos@yaman.com.br)

ORGANIZATION=$ORG
if [ -z $ORG ] ; then
	echo "[-] Necessario definir a ORG Azure Devops"
	echo "    #export ORG=<org>"
	echo "    #docker run <container> -e ORG=<ORG>"
	exit 1
fi
API_VERSION="6.0"
CSV=release.csv
clear

>$CSV
#Condição para checar se o PAT foi definido
if [ -z $PAT ] ; then
        echo "[-] Necessario definir a variavel PAT com o token de autenticação com o Azure Devops"
        echo "  Use: export PAT=<token>"
        exit 1
fi
projects=$(curl -s -u :$PAT "https://dev.azure.com/$ORGANIZATION/_apis/projects?api-version=$API_VERSION" | jq -r '.value[].name')
IFS=$'\n'
for project in $projects
  do
    echo "################################################################################"
    echo "[+] Iniciando checagem no projeto: \"$project\"..."
    echo "################################################################################"
    proj=`echo $project | sed -e 's/ /%20/g' -e 's/é/%C3%A9/g' -e 's/ã/%C3%A3/g' -e 's/â/%C3%A2/g' -e 's/õ/%C3%B5/g' -e 's/é/%C3%A9/g' -e 's/ã/%C3%A3/g' -e 's/ç/%C3%A7/g' -e 's/Ç/%C3%87/g'`
    for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/definitions?api-version='$API_VERSION'&$top=5000' | jq -r '.value[] | "\(.id)"'`
      do
        for row in $release
          do
            for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/releases?definitionId='$row'&queryOrder=descending&$expand=environments&api-version='$API_VERSION'&$top=5000' |  jq -r '.value[] | "\"\(.projectReference.name)\",\"\(.releaseDefinition.name)\",\"\(.name)\",\"\(.environments[0].name)\",\"\(.environments[0].triggerReason)\",\(.createdOn),\"\(._links.web.href)\",\"\(.environments[0].deploySteps[].operationStatus)\",\"\(.environments[0].deploySteps[].status)\",\"\(.environments[0].deploySteps[].reason)\",\"\(.environments[0].deploySteps[].requestedFor.uniqueName)\",\"\(.environments[0].deploySteps[].attempt)\",\(.environments[0].deploySteps[].queuedOn),\(.environments[0].deploySteps[].lastModifiedOn)"' 2>/dev/null`
             do
                                stg_proj=`echo $release | cut -d "," -f1`
                                stg_rel=`echo $release | cut -d "," -f2`
                                stg_relDef=`echo $release | cut -d "," -f3`
                                stg_stage=`echo $release | cut -d "," -f4`
                                stg_stageTrigger=`echo $release | cut -d '"' -f10`
                                stg_url=`echo $release | cut -d '"' -f12`
                                stg_aprv=`echo $release | cut -d  '"' -f14`
                                stg_stat=`echo $release | cut -d "," -f9`
                                stg_stageTrig=`echo $release | cut -d "," -f10`
                                stg_requester=`echo $release | cut -d  '"' -f20`
                                stg_attempt=`echo $release | cut -d "," -f12`
                                stg_start_time=`echo $release |  cut -d '"' -f11| tr -d ","`
                                stg_q_time=`echo $release | cut -d '"' -f23| cut -d "," -f2`
                                stg_f_time=`echo $release | cut -d '"' -f23| cut -d "," -f3`
                                stg_start_time=`date --date=''$stg_start_time'' '+%Y-%m-%d %H:%M:%S'`
                                stg_q_time=`date --date=''$stg_q_time'' '+%Y-%m-%d %H:%M:%S'`
                                stg_f_time=`date --date=''$stg_f_time'' '+%Y-%m-%d %H:%M:%S'`
                                stg_duration=$((`date -d "$stg_f_time" '+%s'` - `date -d "$stg_start_time" '+%s'`))
                                echo "$stg_proj, $stg_rel, $stg_relDef, $stg_stage, \"$stg_stageTrigger\", \"$stg_start_time\", \"$stg_url\", \"$stg_aprv\", $stg_stat, $stg_stageTrig, \"$stg_requester\", $stg_attempt, \"$stg_q_time\", \"$stg_f_time\", \"$stg_duration\"" >>$CSV
                                #echo "$stg_proj, $stg_rel, $stg_relDef, $stg_stage, $stg_stageTrigger, \"$stg_start_time\", $stg_url, $stg_aprv, $stg_stat, $stg_stageTrig, $stg_requester, $stg_attempt, \"$stg_q_time\", \"$stg_f_time\", \"$stg_duration\"" >> $CSV
                                echo "$project - Coletando release $stg_stage..."

              done
            for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/releases?definitionId='$row'&queryOrder=descending&$expand=environments&api-version='$API_VERSION'&$top=5000' |  jq -r '.value[] | "\"\(.projectReference.name)\",\"\(.releaseDefinition.name)\",\"\(.name)\",\"\(.environments[1].name)\",\"\(.environments[1].triggerReason)\",\(.createdOn),\"\(._links.web.href)\",\"\(.environments[1].deploySteps[].operationStatus)\",\"\(.environments[1].deploySteps[].status)\",\"\(.environments[1].deploySteps[].reason)\",\"\(.environments[1].deploySteps[].requestedFor.uniqueName)\",\"\(.environments[1].deploySteps[].attempt)\",\(.environments[1].deploySteps[].queuedOn),\(.environments[1].deploySteps[].lastModifiedOn)"' 2>/dev/null`
              do
                                int_proj=`echo $release | cut -d "," -f1`
                                int_rel=`echo $release | cut -d "," -f2`
                                int_relDef=`echo $release | cut -d "," -f3`
                                int_stage=`echo $release | cut -d "," -f4`
                                int_stageTrigger=`echo $release | cut -d '"' -f10`
                                int_url=`echo $release | cut -d '"' -f12`
                                int_aprv=`echo $release | cut -d  '"' -f14`
                                int_stat=`echo $release | cut -d "," -f9`
                                int_stageTrig=`echo $release | cut -d "," -f10`
                                int_requester=`echo $release | cut -d  '"' -f20`
                                int_attempt=`echo $release | cut -d "," -f12`
                                int_start_time=`echo $release |  cut -d '"' -f11| tr -d ","`
                                int_q_time=`echo $release | cut -d '"' -f23| cut -d "," -f2`
                                int_f_time=`echo $release | cut -d '"' -f23| cut -d "," -f3`
                                int_start_time=`date --date=''$int_start_time'' '+%Y-%m-%d %H:%M:%S'`
                                int_q_time=`date --date=''$int_q_time'' '+%Y-%m-%d %H:%M:%S'`
                                int_f_time=`date --date=''$int_f_time'' '+%Y-%m-%d %H:%M:%S'`
                                int_duration=$((`date -d "$int_f_time" '+%s'` - `date -d "$int_start_time" '+%s'`))
                                echo "$int_proj, $int_rel, $int_relDef, $int_stage, \"$int_stageTrigger\", \"$int_start_time\", \"$int_url\", \"$int_aprv\", $int_stat, $int_stageTrig, \"$int_requester\", $int_attempt, \"$int_q_time\", \"$int_f_time\", \"$int_duration\"" >>$CSV
                                #echo "$int_proj, $int_rel, $int_relDef, $int_stage, $int_stageTrigger, \"$int_start_time\", $int_url, $int_aprv, $int_stat, $int_stageTrig, $int_requester, $int_attempt, \"$int_q_time\", \"$int_f_time\", \"$int_duration\"" >> $CSV
                                echo "$project - Coletando release $int_stage..."

              done
	     for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/releases?definitionId='$row'&queryOrder=descending&$expand=environments&api-version='$API_VERSION'&$top=5000' |  jq -r '.value[] | "\"\(.projectReference.name)\",\"\(.releaseDefinition.name)\",\"\(.name)\",\"\(.environments[1].name)\",\"\(.environments[2].triggerReason)\",\(.createdOn),\"\(._links.web.href)\",\"\(.environments[2].deploySteps[].operationStatus)\",\"\(.environments[2].deploySteps[].status)\",\"\(.environments[2].deploySteps[].reason)\",\"\(.environments[2].deploySteps[].requestedFor.uniqueName)\",\"\(.environments[2].deploySteps[].attempt)\",\(.environments[2].deploySteps[].queuedOn),\(.environments[2].deploySteps[].lastModifiedOn)"' 2>/dev/null`

                do
			        prd_proj=`echo $release | cut -d "," -f1`
                                prd_rel=`echo $release | cut -d "," -f2`
                                prd_relDef=`echo $release | cut -d "," -f3`
                                prd_stage=`echo $release | cut -d "," -f4`
                                prd_stageTrigger=`echo $release | cut -d '"' -f10`
                                prd_url=`echo $release | cut -d '"' -f12`
                                prd_aprv=`echo $release | cut -d  '"' -f14`
                                prd_stat=`echo $release | cut -d "," -f9`
                                prd_stageTrig=`echo $release | cut -d "," -f10`
                                prd_requester=`echo $release | cut -d  '"' -f20`
                                prd_attempt=`echo $release | cut -d "," -f12`
                                prd_start_time=`echo $release |  cut -d '"' -f11| tr -d ","`
                                prd_q_time=`echo $release | cut -d '"' -f23| cut -d "," -f2`
                                prd_f_time=`echo $release | cut -d '"' -f23| cut -d "," -f3`
                                prd_start_time=`date --date=''$prd_start_time'' '+%Y-%m-%d %H:%M:%S'`
                                prd_q_time=`date --date=''$prd_q_time'' '+%Y-%m-%d %H:%M:%S'`
                                prd_f_time=`date --date=''$prd_f_time'' '+%Y-%m-%d %H:%M:%S'`
                                prd_duration=$((`date -d "$prd_f_time" '+%s'` - `date -d "$prd_start_time" '+%s'`))
                                echo "$prd_proj, $prd_rel, $prd_relDef, $prd_stage, \"$prd_stageTrigger\", \"$prd_start_time\", \"$prd_url\", \"$prd_aprv\", $prd_stat, $prd_stageTrig, \"$prd_requester\", $prd_attempt, \"$prd_q_time\", \"$prd_f_time\", \"$prd_duration\"" >>$CSV
                                echo "$project - Coletando release $prd_stage..."
                done
             for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/releases?definitionId='$row'&queryOrder=descending&$expand=environments&api-version='$API_VERSION'&$top=5000' |  jq -r '.value[] | "\"\(.projectReference.name)\",\"\(.releaseDefinition.name)\",\"\(.name)\",\"\(.environments[3].name)\",\"\(.environments[3].triggerReason)\",\(.createdOn),\"\(._links.web.href)\",\"\(.environments[3].deploySteps[].operationStatus)\",\"\(.environments[3].deploySteps[].status)\",\"\(.environments[3].deploySteps[].reason)\",\"\(.environments[3].deploySteps[].requestedFor.uniqueName)\",\"\(.environments[3].deploySteps[].attempt)\",\(.environments[3].deploySteps[].queuedOn),\(.environments[3].deploySteps[].lastModifiedOn)"' 2>/dev/null`
	
              do
                                other_proj=`echo $release | cut -d "," -f1`
                                other_rel=`echo $release | cut -d "," -f2`
                                other_relDef=`echo $release | cut -d "," -f3`
                                other_stage=`echo $release | cut -d "," -f4`
                                other_stageTrigger=`echo $release | cut -d '"' -f10`
                                other_url=`echo $release | cut -d '"' -f12`
                                other_aprv=`echo $release | cut -d  '"' -f14`
                                other_stat=`echo $release | cut -d "," -f9`
                                other_stageTrig=`echo $release | cut -d "," -f10`
                                other_requester=`echo $release | cut -d  '"' -f20`
                                other_attempt=`echo $release | cut -d "," -f12`
                                other_start_time=`echo $release |  cut -d '"' -f11| tr -d ","`
                                other_q_time=`echo $release | cut -d '"' -f23| cut -d "," -f2`
                                other_f_time=`echo $release | cut -d '"' -f23| cut -d "," -f3`
                                other_start_time=`date --date=''$other_start_time'' '+%Y-%m-%d %H:%M:%S'`
                                other_q_time=`date --date=''$other_q_time'' '+%Y-%m-%d %H:%M:%S'`
                                other_f_time=`date --date=''$other_f_time'' '+%Y-%m-%d %H:%M:%S'`
                                other_duration=$((`date -d "$other_f_time" '+%s'` - `date -d "$other_start_time" '+%s'`))
                                echo "$other_proj, $other_rel, $other_relDef, $other_stage, \"$other_stageTrigger\", \"$other_start_time\", \"$other_url\", \"$other_aprv\", $other_stat, $other_stageTrig, \"$other_requester\", $other_attempt, \"$other_q_time\", \"$other_f_time\", \"$other_duration\"" >>$CSV
                                #echo "$other_proj, $other_rel, $other_relDef, $other_stage, $other_stageTrigger, \"$other_start_time\", $other_url, $other_aprv, $other_stat, $other_stageTrig, $other_requester, $other_attempt, \"$other_q_time\", \"$other_f_time\", \"$other_duration\"" >> $CSV
                                echo "$project - Coletando release $other_stage..."

              done
            for release in `curl -s -u :$PAT 'https://vsrm.dev.azure.com/'$ORGANIZATION'/'$proj'/_apis/release/releases?definitionId='$row'&queryOrder=descending&$expand=environments&api-version='$API_VERSION'&$top=5000' |  jq -r '.value[] | "\"\(.projectReference.name)\",\"\(.releaseDefinition.name)\",\"\(.name)\",\"\(.environments[4].name)\",\"\(.environments[4].triggerReason)\",\(.createdOn),\"\(._links.web.href)\",\"\(.environments[4].deploySteps[].operationStatus)\",\"\(.environments[4].deploySteps[].status)\",\"\(.environments[4].deploySteps[].reason)\",\"\(.environments[4].deploySteps[].requestedFor.uniqueName)\",\"\(.environments[4].deploySteps[].attempt)\",\(.environments[4].deploySteps[].queuedOn),\(.environments[4].deploySteps[].lastModifiedOn)"' 2>/dev/null`

             do
		                other2_proj=`echo $release | cut -d "," -f1`
                                other2_rel=`echo $release | cut -d "," -f2`
                                other2_relDef=`echo $release | cut -d "," -f3`
                                other2_stage=`echo $release | cut -d "," -f4`
                                other2_stageTrigger=`echo $release | cut -d '"' -f10`
                                other2_url=`echo $release | cut -d '"' -f12`
                                other2_aprv=`echo $release | cut -d  '"' -f14`
                                other2_stat=`echo $release | cut -d "," -f9`
                                other2_stageTrig=`echo $release | cut -d "," -f10`
                                other2_requester=`echo $release | cut -d  '"' -f20`
                                other2_attempt=`echo $release | cut -d "," -f12`
                                other2_start_time=`echo $release |  cut -d '"' -f11| tr -d ","`
                                other2_q_time=`echo $release | cut -d '"' -f23| cut -d "," -f2`
                                other2_f_time=`echo $release | cut -d '"' -f23| cut -d "," -f3`
                                other2_start_time=`date --date=''$other2_start_time'' '+%Y-%m-%d %H:%M:%S'`
                                other2_q_time=`date --date=''$other2_q_time'' '+%Y-%m-%d %H:%M:%S'`
                                other2_f_time=`date --date=''$other2_f_time'' '+%Y-%m-%d %H:%M:%S'`
                                other2_duration=$((`date -d "$other2_f_time" '+%s'` - `date -d "$other2_start_time" '+%s'`))
                                echo "$other2_proj, $other2_rel, $other2_relDef, $other2_stage, \"$other2_stageTrigger\", \"$other2_start_time\", \"$other2_url\", \"$other2_aprv\", $other2_stat, $other2_stageTrig, \"$other2_requester\", $other2_attempt, \"$other2_q_time\", \"$other2_f_time\", \"$other2_duration\"" >>$CSV
                                #echo "$other2_proj, $other2_rel, $other2_relDef, $other2_stage, $other2_stageTrigger, \"$other2_start_time\", $other2_url, $other2_aprv, $other2_stat, $other2_stageTrig, $other2_requester, $other2_attempt, \"$other2_q_time\", \"$other2_f_time\", \"$other2_duration\"" >> $CSV
                                echo "$project - Coletando release $other2_stage..."
              done

          done
      done
      echo
      echo "################################################################################"
      echo "[+] Fim da checagem no projeto \"$project\""
      echo "  - Arquivo $CSV com `wc -l $CSV | cut -d " " -f1` linhas"
      echo "################################################################################"
done
echo
echo "################################################################################"
echo "[+] Fim da execução: Criado arquivo $CSV com `wc -l $CSV` linhas."
echo "################################################################################"
sort -u $CSV > $CSV-new
mv -v $CSV-new $CSV
sed -i '1 i\\"Projeto\", \"release\", \"Release Definition\", \"Stage\", \"Trigger\", \"Data de criacao\", \"URL\", \"Aprovacao\", \"Stage Status\", \"Stage Trigger\", \"Requested\", \"Tentativas\", \"Data de Inicio\", \"Data de fim\", \"Duracao\"' $CSV
echo "[+] Header do CSV:"
head -1 $CSV
echo "[+] Fazendo o Load para o Postgres"
bash loadToPg.sh
