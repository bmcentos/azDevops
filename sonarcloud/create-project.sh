      #!/bin/bash
      clear
      #Variavel para setar as cores
      GREEN="\e[1;32m"
      DEFAULT="\e[0m"
      RED="\e[1;31m"
      YELLOW="\e[1;33m"
      BLUE="\e[1;36m"

      # Header
      echo ""
      echo -e "${GREEN}===============================================================================${DEFAULT}"
      echo -e "${BLUE}Setup SonarCloud Script"
      echo -e "${GREEN}===============================================================================${DEFAULT}"
      echo ""
      echo -e "${BLUE}[+] Getting Tokens in KeyVault${DEFAULT}"

      #COLETANDO SECRETS DO AZURE KEYVAUT
      REPO="Yes"
      KeyVault=$KeyVault
      if [ -z $KeyVault ] ;then
              echo -e "${RED}[-] KeyVault não definido, por favor defina a variavel!!!"
              echo "    export KeyVault=<az-keyVault>"
              exit 1
      fi
      SonarCloudToken=$(az keyvault secret show --vault-name $KeyVault --name "SonarCloudToken" --query "value" -o tsv)
      SonarCloudDevOpsToken=$(az keyvault secret show --vault-name $KeyVault --name "SonarCloudDevOpsToken" --query "value" -o tsv)
      Org=$org
      if [ -z $org ] ; then
              echo "${RED}[-] Por favor defina a org-key do SonarCloud"
              echo "     #export org=<org-key>"
             exit 1
      fi

      if [ -z $SonarCloudToken ] || [ -z $SonarCloudDevOpsToken ] ; then
              echo -e "${RED}[-] Key vault não retornou SonarCloudToken ou/e SonarCloudDevOpsToken!!!"
              echo -e "     - Por favor verificar svc_principal, tenant e secret${DEFAULT}"
              echo -e "     - Se necessario defina as envs SonarCloudToken e SonarCloudDevOpsToken"
              exit 1
      else

              echo -e "           ${GREEN}[+] KeyVault: $KeyVault done!${DEFAULT}"
      fi
      # AUTENTICANDO NO SONARCLOUD COM O TOKEN
      echo ""
      echo -e "${BLUE}[+] Authenticating in SonarCloud${DEFAULT}"
      Token=$(echo -n "$SonarCloudToken:" | base64)
      BasicAuth="Basic $Token"
      Headers="Authorization: $BasicAuth"
      ProjectsURL="https://sonarcloud.io/api/projects/search?organization=%s&ps=10"
      ProjectsURLGet=$(printf "$ProjectsURL" "$Org")

      # FAZENDO A EQUISIÇÃO NA API DO SONAR PARA CHECAR SE O PROJETO EXISTE
      GetProjects=$(curl -s -H "$Headers" "$ProjectsURLGet")

      # VERIFICA SE O PROJETO EXISTE E SE A REQUISIÇÃO OCORRE COM SUCESSO
      if [[ $(echo "$GetProjects" | jq -r ".paging.total") ]]; then
          echo -e "          ${GREEN}[+]  Token: valid!"
          echo -e "          ${GREEN}[+]  Total of projects found: ${RED}$(echo "$GetProjects" | jq -r ".paging.total")${DEFAULT}"
      else
          echo -e "           ${RED} [-] Token: invalid!"
          exit 1
      fi

      # COLETA O NOME DO APPPATH (VARIAVEL PASSADA PARA MONOREPO QUE SERÁ USADA COMO SULFIXO DO NOME DO PROJETO SE EXISTENTE)
      # PROJETO NOMEADO COM O NOME DO REPOSITORIO GIT
      AppName=$(echo $APPPATH | tr '/' '-')
      # CONCATENANDO O NOME DO REPO COM O APPPATH
      BuildRepositoryNameURL="$BUILD_REPOSITORY_NAME"
      BuildRepositoryNameURL=$(echo $BuildRepositoryNameURL-$AppName | tr '.' '-' | tr -d ' ' | tr -d 'ã')

      if [ -z $AppName ] ; then
              BuildRepositoryNameURL=`echo $BuildRepositoryNameURL| sed 's/-$//'`
              echo -e "${YELLOW}[!!] This project is not a MonoRepo: $BuildRepositoryNameURL${DEFAULT}"
              AppName=$BuildRepositoryNameURL
              BuildRepositoryNameDisplay=$(echo $BUILD_REPOSITORY_NAME _ | tr -d ' ')
              BuildRepositoryNameDisplay=$(echo $BuildRepositoryNameDisplay | tr '.' '-' | tr '_' '-' | tr -d 'ã'|sed 's/-$//'| tr [A-Z] [a-z])
      else
              echo -e "${YELLOW}[!!] This project is MonoRepo: $BuildRepositoryNameURL${DEFAULT}"
              BuildRepositoryNameDisplay=$(echo $BUILD_REPOSITORY_NAME _ | tr -d ' ')
              BuildRepositoryNameDisplay=$(echo $BuildRepositoryNameDisplay$AppName | tr '.' '-' | tr '_' '-' | tr -d 'ã'|sed 's/-$//' | tr [A-Z] [a-z])
      fi

      echo -e "                    ${GREEN}[+] AppName = $AppName${DEFAULT}"
      echo -e "                    ${GREEN}[+] URL Name = $BuildRepositoryNameURL${DEFAULT}"
      echo -e "                    ${GREEN}[+] Display Name = $BuildRepositoryNameDisplay${DEFAULT}"


      # CRIANDO O PEOJETO
      echo ""
      echo -e "${BLUE}[+] Creating the project: $BuildRepositoryNameURL${YELLOW}"
      ProjectURL="https://sonarcloud.io/api/projects/search?organization=%s&projects=%s"
      VerifyProjectURL=$(printf "$ProjectURL" "$Org" "$BuildRepositoryNameURL")

      # VERIFICA SE O PROJETO EXISTE
      GetProject=$(curl -s -H "$Headers" "$VerifyProjectURL")

      # VERIFICA SE O PROJETO JA EXISTE, SE NÃO CRIA UM NOVO
      if [[ $(echo "$GetProject" | jq -r ".components[].key") ]]; then
        echo -e "${YELLOW}           [!!]  Project: $BuildRepositoryNameDisplay already exists${DEFAULT}"
      else
          REPO="No"
          CreateProjectURL="https://sonarcloud.io/api/projects/create?organization=%s&project=%s&name=%s&visibility=private"
          CreateProjectURLPost=$(printf "$CreateProjectURL" "$Org" "$BuildRepositoryNameURL" "$BuildRepositoryNameURL")
          Post=$(curl -s -X POST -H "$Headers" "$CreateProjectURLPost")
          echo -e "${GREEN}            [+] Project: $BuildRepositoryNameDisplay created!${DEFAULT}"
      fi

      # CONFIGURA O PULL REQUEST
      echo ""
      echo -e "${BLUE}Setup Pull Request Integration${DEFAULT}"

      SetKeyURL="https://sonarcloud.io/api/settings/set?component=%s&key=%s&value=%s"
      PRPost1=$(printf "$SetKeyURL" "$BuildRepositoryNameURL" "sonar.pullrequest.provider" "Azure%20DevOps%20Services")
      PRPost2=$(printf "$SetKeyURL" "$BuildRepositoryNameURL" "sonar.pullrequest.vsts.token.secured" "$SonarCloudDevOpsToken")

      # Set sonar.pullrequest.provider
      echo -e "${GREEN}sonar.pullrequest.provider: Azure DevOps Services${DEFAULT}"
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$PRPost1")
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}  Done!${DEFAULT}"
      else
          echo -e "${RED}  Failed!${DEFAULT}"
          exit 1
      fi

      # Set sonar.pullrequest.vsts.token.secured
      echo -e "${BLUE}sonar.pullrequest.vsts.token.secured: ***${DEFAULT}"
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$PRPost2")
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}Done!${DEFAULT}"
      else
          echo -e "${RED}Failed!${DEFAULT}"
          exit 1
      fi

      # PERIODO PARA ENTRADA DE NOVO CODIGO
      echo ""
      Date="30"
      echo -e "${GREEN}  [+] Setting New Code Period ($Date days default)${DEFAULT}"
      NewCodePeriodPost=$(printf "$SetKeyURL" "$BuildRepositoryNameURL" "sonar.leak.period" "$Date")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$NewCodePeriodPost")
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}  [+] sonar.leak.period: $Date done!${DEFAULT}"
      else
          echo -e "${RED}  [-] sonar.leak.period: $Date failed!${DEFAULT}"
          exit 1
      fi

      # CONFIGURA BRANCHES DE LONGA DURAÇÃO
      echo ""
      echo -e "${GREEN} [+]Set Long living branches pattern${DEFAULT}"
      BranchPattern="(master|main|develop|release).*"
      LongLivingBranchesPatternPost=$(printf "$SetKeyURL" "$BuildRepositoryNameURL" "sonar.branch.longLivedBranches.regex" "$BranchPattern")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$LongLivingBranchesPatternPost")
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}  [+] sonar.branch.longLivedBranches.regex: $BranchPattern done!${DEFAULT}"
      else
          echo -e "${RED}  [-]sonar.branch.longLivedBranches.regex: $BranchPattern failed!${DEFAULT}"
          exit 1
      fi

      # Rename Main Branch
      echo ""
      echo -e "${BLUE}Rename Main Branch${DEFAULT}"
      MainBrachName="main"
      RNURL="https://sonarcloud.io/api/project_branches/rename?name=%s&project=%s"
      RNPost=$(printf "$RNURL" "$MainBrachName" "$BuildRepositoryNameURL")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$RNPost")
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}  [+] Main Branch: $MainBrachName done!${DEFAULT}"
      else
          echo -e "${RED}  [-] Main Branch: $MainBrachName failed!${DEFAULT}"
      fi

      # Create and Set Groups permissions
      echo ""
      echo -e "${BLUE}Setup Groups and Permissions${DEFAULT}"
      GRURLVerify="https://sonarcloud.io/api/user_groups/search?organization=%s&q=%s"
      GRURLCreate="https://sonarcloud.io/api/user_groups/create?organization=%s&name=%s&description=%s"
      GRPermSetURL="https://sonarcloud.io/api/permissions/add_group?organization=%s&projectKey=%s&groupName=%s&permission=%s"

      # Project Group
      GR1Name=$(printf '%s' "$System_TeamProject" | jq -s -R -r @uri)
      GR1NameDesc="Este grupo tem acesso a todos os projetos da área"
      GR1NameDesc=$(printf '%s' "$GR1NameDesc" | jq -s -R -r @uri)
      GR1Post=$(printf "$GRURLCreate" "$Org" "$GR1Name" "$GR1NameDesc")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post")
      GRURLVerifyGet=$(printf "$GRURLVerify" "$Org" "$GR1Name")
      GetGroups=$(curl -s -X GET -H "Content-Type: application/json" -H "$Headers" "$GRURLVerifyGet")
      if echo "$GetGroups" | jq -r '.groups[].name' | grep -q "$System_TeamProject"; then
          echo -e "${YELLOW}  [!!] group: $System_TeamProject already exists!${DEFAULT}"
      else
          response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post")
          echo -e "${GREEN}  [+] create group: $System_TeamProject done!${DEFAULT}"
      fi

      GR1Post2=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR1Name" "user")
      GR1Post3=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR1Name" "codeviewer")
      GR1Post4=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR1Name" "issueadmin")
      GR1Post5=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR1Name" "securityhotspotadmin")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post2")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post3")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post4")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR1Post5")
      echo -e "${GREEN}  [+] setting permissions for group: $System_TeamProject done!${DEFAULT}"

      # Repository Group
      GR2Name="$BuildRepositoryNameURL"
      GR2NameDesc="Este grupo tem acesso somente a esse repositorio"
      GR2NameDesc=$(printf '%s' "$GR2NameDesc" | jq -s -R -r @uri)
      GR2Post=$(printf "$GRURLCreate" "$Org" "$GR2Name" "$GR2NameDesc")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post")
      GRURLVerifyGet=$(printf "$GRURLVerify" "$Org" "$GR2Name")
      GetGroups=$(curl -s -X GET -H "Content-Type: application/json" -H "$Headers" "$GRURLVerifyGet")
      if echo "$GetGroups" | jq -r '.groups[].name' | grep -q "$BuildRepositoryNameDisplay"; then
          echo -e "${YELLOW}  [!!] group: $BuildRepositoryNameDisplay already exists!${DEFAULT}"
      else
          response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post")
          echo -e "${GREEN}  [+] create group: $BuildRepositoryNameDisplay done!${DEFAULT}"
      fi

      GR2Post2=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR2Name" "user")
      GR2Post3=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR2Name" "codeviewer")
      GR2Post4=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR2Name" "issueadmin")
      GR2Post5=$(printf "$GRPermSetURL" "$Org" "$BuildRepositoryNameURL" "$GR2Name" "securityhotspotadmin")

      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post2")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post3")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post4")
      response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$GR2Post5")
      echo -e "${GREEN}setting permissions for group: $BuildRepositoryNameDisplay done!${DEFAULT}"

      # Query Sonar User
      echo ""
      echo -e "${BLUE}Add user to group $BuildRepositoryNameDisplay, if exists${DEFAULT}"
      UserMail=$(printf '%s' "$BUILD_REQUESTEDFOREMAIL" | jq -s -R -r @uri)
      UserURL="https://sonarcloud.io/api/users/search?q=%s"
      UserGet=$(printf "$UserURL" "$UserMail")
      User=$(curl -s -X GET -H "Content-Type: application/json" -H "$Headers" "$UserGet")

      if [ `echo "$User" | jq .users[].login| wc -l` -eq "1" ] ; then
          AddUserURL="https://sonarcloud.io/api/user_groups/add_user?organization=%s&name=%s&login=%s"
          AddUserPost=$(printf "$AddUserURL" "$Org" "$BuildRepositoryNameURL" "$User.users.login")
          response=$(curl -s -X POST -H "Content-Type: application/json" -H "$Headers" -d "" "$AddUserPost")
          echo -e "${GREEN}  [+] user: $BUILD_REQUESTEDFOREMAIL added!${DEFAULT}"
      else
          echo -e "${RED}  [-] user: $BUILD_REQUESTEDFOREMAIL not found on SonarCloud!${DEFAULT}"
      fi

      # List Variables
      echo ""
      echo ""
      echo -e "${BLUE}List Variables${DEFAULT}"
      echo "  - $VerifyProjectURL"
      echo "  - $GetProject"
      echo "  - $BuildRepositoryNameURL"
      echo "  - $BuildRepositoryNameDisplay"
      echo "  - `echo $GetProject | jq .components[]`"
      echo -e "${BLUE}Status - repository exists? ${GREEN}$REPO${DEFAULT}"
      echo "##vso[task.setvariable variable=repo_exists;isOutput=true]$REPO"
      echo ""
      echo "=============================================================================="
