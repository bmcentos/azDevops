<!DOCTYPE html>
/* Maintener By Bruno Miquelini (bruno.santos@yaman.com.br
<html>
<head>
    <title>Criação dos charts para utilização na pipeline DevOps</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css"
      rel="stylesheet"
      integrity="sha384-BmbxuPwQa2lc/FVzBcNJ7UAyJxM6wuqIj61tLrc4wSX0szH/Ev+nYRRuWlolflfl"
      crossorigin="anonymous">
   <style>
    /* Define a CSS class with the desired font styles */
    .black-font {
      font-family: Arial, sans-serif;
      font-size: 16px;
      font-weight: bold;
    }
    .submit-button {
      background-color: #4CAF50; /* Cor de fundo */
      color: white; /* Cor do texto */
      padding: 10px 30px; /* Preenchimento interno */
      font-size: 20px; /* Tamanho da fonte */
      border: none; /* Remover borda */
      cursor: pointer; /* Alterar cursor ao passar o mouse */
      border-radius: 4px; /* Arredondar bordas */
    }
    .icon-link {
      display: inline-flex;
      align-items: center;
    }

    .icon-link img {
      margin-right: 5px;
    }
   </style>
</head>
<body style="padding: 5rem;">
 <header>

    <nav class="navbar navbar-expand-md navbar-dark fixed-top bg-dark">
      <div class="container-fluid">
        <a class="navbar-brand" href="https://dev.azure.com/Cerc-Recebiveis/Corporate/_git/Helm?path=/charts/cercHelm/values.yaml">CERC Chart
        <img src="img.png" alt="Ícone">
      </a>
      </div>
    </nav>
  </header>
    <h2>Formulario de criação de charts</h2>
    <form method="POST" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>">
        <label  class="black-font" for="app">App Name:</label>
        <input type="text" name="app" id="app" value="cerc-app"><br><br>

        <label class="black-font" for="namespace">Namespace:</label>
        <input type="text" name="namespace" id="namespace" value="cerc"><br><br>

        <label  class="black-font" for="containerPort">Container Port:</label>
        <input type="text" name="containerPort" id="containerPort" value="8080"><br><br>

        <input type="checkbox" name="enableServiceAccountManifest" id="enableServiceAccountManifest">
        <label  class="black-font" for="enableServiceAccountManifest">Enable Service Account Manifest</label><br><br>

        <div id="serviceAccountManifestOptions" style="display: none;">
            <label for="serviceAccountName">Service Account Name:</label>
            <input type="text" name="serviceAccountName" id="serviceAccountName"><br><br>

            <label for="gcpProject">GCP Project:</label>
            <input type="text" name="gcpProject" id="gcpProject"><br><br>
        </div>

        <input type="checkbox" name="enableHpaManifest" id="enableHpaManifest">
        <label  class="black-font" for="enableHpaManifest">Enable HPA Manifest</label><br><br>

        <div id="hpaManifestOptions" style="display: none;">
            <label for="minReplicas">Min Replicas:</label>
            <input type="text" name="minReplicas" id="minReplicas"><br><br>

            <label for="maxReplicas">Max Replicas:</label>
            <input type="text" name="maxReplicas" id="maxReplicas"><br><br>

            <label for="targetCPU">Target CPU:</label>
            <input type="text" name="targetCPU" id="targetCPU"><br><br>

            <label for="targetMemory">Target Memory:</label>
            <input type="text" name="targetMemory" id="targetMemory"><br><br>
        </div>

        <input type="checkbox" name="enableReadinessProbe" id="enableReadinessProbe">
        <label  class="black-font" for="enableReadinessProbe">Enable Readiness Probe</label><br><br>

        <div id="readinessProbeOptions" style="display: none;">
            <label for="pathReadinessProbe">Path:</label>
            <input type="text" name="pathReadinessProbe" id="pathReadinessProbe"><br><br>
        </div>

        <input type="checkbox" name="enableLivenessProbe" id="enableLivenessProbe">
        <label  class="black-font" for="enableLivenessProbe">Enable Liveness Probe</label><br><br>

        <div id="livenessProbeOptions" style="display: none;">
            <label for="pathLivenessProbe">Path:</label>
            <input type="text" name="pathLivenessProbe" id="pathLivenessProbe"><br><br>
        </div>

        <input type="checkbox" name="enableSecretsManifest" id="enableSecretsManifest">
        <label  class="black-font" for="enableSecretsManifest">Enable Secrets Manifest</label><br><br>
        <div id="secretsManifestOptions" style="display: none;">
            <label  class="black-font" for="secrets">Secrets:</label>
            <textarea id="secrets" name="secrets" rows="10" cols="50">
DB_CONNECTION
CLIENT_ID
           </textarea>
        </div>

        <input type="checkbox" name="envsDeployment" id="envsDeployment">
        <label  class="black-font" for="envsDeployment">Enable Enviroments</label><br><br>
        <div id="envsOptions" style="display: none;">
            <label  class="black-font" for="envs">Envs:</label>
            <textarea id="envs" name="envs" rows="10" cols="50">
env="stg"
uri="http://xxxxx"
           </textarea><br>
        </div>
        <br>
        <input class="submit-button" type="submit" name="submit" value="Create" onclick="exibirMensagem()">
    </form>
    <script>
        const serviceAccountManifestOptions = document.getElementById('serviceAccountManifestOptions');
        const enableServiceAccountManifestCheckbox = document.getElementById('enableServiceAccountManifest');
        enableServiceAccountManifestCheckbox.addEventListener('change', function() {
            serviceAccountManifestOptions.style.display = this.checked ? 'block' : 'none';
        });

        const hpaManifestOptions = document.getElementById('hpaManifestOptions');
        const enableHpaManifestCheckbox = document.getElementById('enableHpaManifest');
        enableHpaManifestCheckbox.addEventListener('change', function() {
            hpaManifestOptions.style.display = this.checked ? 'block' : 'none';
        });

        const readinessProbeOptions = document.getElementById('readinessProbeOptions');
        const enableReadinessProbeCheckbox = document.getElementById('enableReadinessProbe');
        enableReadinessProbeCheckbox.addEventListener('change', function() {
            readinessProbeOptions.style.display = this.checked ? 'block' : 'none';
        });

        const livenessProbeOptions = document.getElementById('livenessProbeOptions');
        const enableLivenessProbeCheckbox = document.getElementById('enableLivenessProbe');
        enableLivenessProbeCheckbox.addEventListener('change', function() {
            livenessProbeOptions.style.display = this.checked ? 'block' : 'none';
        });

        const secretsManifestOptions = document.getElementById('secretsManifestOptions');
        const enableSecretsManifestCheckbox = document.getElementById('enableSecretsManifest');
        enableSecretsManifestCheckbox.addEventListener('change', function() {
            secretsManifestOptions.style.display = this.checked ? 'block' : 'none';
        });

        const envsOptions = document.getElementById('envsOptions');
        const enableEnvCheckbox = document.getElementById('envsDeployment');
        enableEnvCheckbox.addEventListener('change', function() {
            envsOptions.style.display = this.checked ? 'block' : 'none';
        });

    </script>

    <?php
    // Cria o diretório "charts" caso não exista
    if (!is_dir('charts')) {
        echo "Criando charts";
        mkdir('charts');
    }
        // Cria o diretório "charts/templates" caso não exista
    if (!is_dir('charts/templates')) {
        echo "Criando charts/templates";
        mkdir('charts/templates');
        $content = "{{- include \"cercHelm.main\" . }}\n";
        $file = fopen('charts/templates/manifest.yaml', 'w');
        fwrite($file, $content);
        fclose($file);
    }


    // Cria a estrutura do diretório "charts/environments/stg"
    $directory = 'charts/environments/stg';
    if (!is_dir($directory)) {
        mkdir($directory, 0777, true);
    }
        // Coletando POST recebidos do formulario
        if ($_SERVER["REQUEST_METHOD"] === "POST") {
            $app = $_POST["app"];
            $namespace = $_POST["namespace"];
            $containerPort = $_POST["containerPort"];
            $enableServiceAccountManifest = isset($_POST["enableServiceAccountManifest"]);
            $serviceAccountName = $_POST["serviceAccountName"];
            $gcpProject = $_POST["gcpProject"];
            $enableHpaManifest = isset($_POST["enableHpaManifest"]);
            $minReplicas = $_POST["minReplicas"];
            $maxReplicas = $_POST["maxReplicas"];
            $targetCPU = $_POST["targetCPU"];
            $targetMemory = $_POST["targetMemory"];
            $enableReadinessProbe = isset($_POST["enableReadinessProbe"]);
            $pathReadinessProbe = $_POST["pathReadinessProbe"];
            $enableLivenessProbe = isset($_POST["enableLivenessProbe"]);
            $pathLivenessProbe = $_POST["pathLivenessProbe"];
            $enableSecretsManifest = isset($_POST["enableSecretsManifest"]);
            $envsDeployment = isset($_POST["envsDeployment"]);
            $secretValues = $_POST["secretValues"];
            $cpuLimit = isset($_POST["cpuLimit"]) ? $_POST["cpuLimit"] : "200m";
            $memoryLimit = isset($_POST["memoryLimit"]) ? $_POST["memoryLimit"] : "200Mi";
            $cpuRequest = isset($_POST["cpuRequest"]) ? $_POST["cpuRequest"] : "50m";
            $memoryRequest = isset($_POST["memoryRequest"]) ? $_POST["memoryRequest"] : "50Mi";
            $valuesFilePath = "./charts/environments/stg/values.yaml";
            $file = fopen($valuesFilePath, "w");

            // Escrevendo Global Values
            fwrite($file, "globalValues:\n");
            fwrite($file, "  workloadType: Deployment\n");
            fwrite($file, "  port:\n");
            fwrite($file, "    number: $containerPort\n");
            fwrite($file, "    targetPort: $containerPort\n");
            fwrite($file, "    protocol: TCP\n");
            fwrite($file, "  namespace: $namespace\n");
            fwrite($file, "  enableServiceAccountManifest: " . ($enableServiceAccountManifest ? "true" : "false") . "\n");
            fwrite($file, "  enableHpaManifest: " . ($enableHpaManifest ? "true" : "false") . "\n");
            fwrite($file, "  enableSecretsManifest: " . ($enableSecretsManifest ? "true" : "false") . "\n");

            // Habilitando Service Account
            if ($enableServiceAccountManifest) {
                fwrite($file, "\nserviceAccountManifest:\n");
                fwrite($file, "  serviceAccountName: $serviceAccountName\n");
                fwrite($file, "  gcpProjectId: $gcpProject\n");
            }

            // Habilitando HPA manifesto
            if ($enableHpaManifest) {
                fwrite($file, "\nhorizontalPodAutoScalerManifest:\n");
                fwrite($file, "  apiVersion: autoscaling/v2\n");
                fwrite($file, "  minReplicas: $minReplicas\n");
                fwrite($file, "  maxReplicas: $maxReplicas\n");
                fwrite($file, "  targetCPUUtilizationPercentage: $targetCPU\n");
                fwrite($file, "  targetMemoryUtilizationPercentage: $targetMemory\n");
            }

            // Manifesto de deploy
            fwrite($file, "\ndeploymentManifest:\n");
            fwrite($file, "  annotations: {}\n");
            fwrite($file, "  replicaCount: 1\n");
            fwrite($file, "  initContainerEnabled: false\n");
            fwrite($file, "  nodePool:\n");
            fwrite($file, "    enable: false\n");
            fwrite($file, "    name:\n");
            fwrite($file, "  updateStrategy:\n");
            fwrite($file, "    type: RollingUpdate\n");
            fwrite($file, "  image:\n");
            fwrite($file, "    pullPolicy: IfNotPresent\n");
            fwrite($file, "    repository: \"\"\n");
            // Habilitar ReaqdnessProbe
            if ($enableReadinessProbe) {
                fwrite($file, "  readinessProbe:\n");
                fwrite($file, "    enable: true\n");
                fwrite($file, "    failureThreshold: 3\n");
                fwrite($file, "    httpGet:\n");
                fwrite($file, "      path: $pathReadinessProbe\n");
                fwrite($file, "      port: $containerPort\n");
                fwrite($file, "      scheme: HTTP\n");
                fwrite($file, "    periodSeconds: 80\n");
                fwrite($file, "    successThreshold: 1\n");
                fwrite($file, "    timeoutSeconds: 80\n");
            } else {
                // Caso o ReadnessProble não esteja habilitado
                fwrite($file, "  readinessProbe:\n");
                fwrite($file, "    enable: false\n");
            }

            // Habilita LivenessProbe
            if ($enableLivenessProbe) {
                fwrite($file, "  livenessProbe:\n");
                fwrite($file, "    enable: true\n");
                fwrite($file, "    failureThreshold: 3\n");
                fwrite($file, "    httpGet:\n");
                fwrite($file, "      path: $pathLivenessProbe\n");
                fwrite($file, "      port: $containerPort\n");
                fwrite($file, "      scheme: HTTP\n");
                fwrite($file, "    periodSeconds: 30\n");
                fwrite($file, "    successThreshold: 1\n");
                fwrite($file, "    timeoutSeconds: 80\n");
            } else {
                // Caso o LivenessProble não esteja habilitado
                fwrite($file, "  livenessProbe:\n");
                fwrite($file, "    enable: false\n");
            }
            // Resources do deployment
            fwrite($file, "  resources:\n");
            fwrite($file, "    limits:\n");
            fwrite($file, "      cpu: \"$cpuLimit\"\n");
            fwrite($file, "      memory: \"$memoryLimit\"\n");
            fwrite($file, "    requests:\n");
            fwrite($file, "      cpu: \"$cpuRequest\"\n");
            fwrite($file, "      memory: \"$memoryRequest\"\n");

            // Secret manifest
            $secrets = isset($_POST["secrets"]) ? $_POST["secrets"] : '';
            $secretList = explode("\n", $secrets);
            if ($enableSecretsManifest) {
                fwrite($file, "\nsecretsManifest:\n");
                fwrite($file, "  type: Opaque\n");
                fwrite($file, "  annotations: {}\n");
                fwrite($file, "  data:\n");
                foreach ($secretList as $secretValue) {
                        $secretValue = trim($secretValue); // Remove espaços em branco no início e no final
                        if (!empty($secretValue)) {
                                $valueDefault = '"empty"';
                                $line = sprintf("    %s: %s\n", $secretValue, $valueDefault);
                                fwrite($file, $line);
                        }
                }
        }
            // EnvToDeployment manifest
            $envs = isset($_POST["envs"]) ? $_POST["envs"] : '';
            $envList = explode("\n", $envs);
            if ($envsDeployment) {
              fwrite($file, "\nenvToDeployment:\n");
              foreach ($envList as $envValue) {
                // Extract the key and value
                if (preg_match('/^(.*?)=(.*)$/', $envValue, $matches)) {
                $key = trim($matches[1]);
                $value = trim($matches[2]);

                // Remove double quotes if present
                if (strpos($value, '"') === 0 && strrpos($value, '"') === strlen($value) - 1) {
                        $value = substr($value, 1, -1);
                }

            fwrite($file, "  $key: \"$value\"\n");
        }
    }
}
            fclose($file);


            // Escrevendo o Chart.yaml
            $content = "apiVersion: v2\n";
            $content .= "name: $app\n";
            $content .= "description: Cerc helm chart\n";
            $content .= "type: application\n";
            $content .= "version: 1.0.0\n";
            $content .= "appVersion: 1.0.0\n";
            $content .= "dependencies:\n";
            $content .= "  - name: cercHelm\n";
            $content .= "    version: 3.4\n";
            $content .= "    repository: gs://cerc-helm-repository-southamerica-east1\n";

            $file = fopen('charts/Chart.yaml', 'w');
            fwrite($file, $content);
            fclose($file);

           // Função para exibir a mensagem de Ok no submit
            function exibirMsg($mensagem, $estilo) {
                echo '<div class="' . $estilo . '">' . $mensagem . '</div>';
            }

           $mensagem = 'Estrutura de charts criada com sucesso no diretorio charts/';
           $estilo = 'alert alert-success'; // Classe CSS para o estilo desejado

           exibirMsg($mensagem, $estilo);

           $origem = 'charts/environments/stg/values.yaml';
           $int = 'charts/environments/int/values.yaml';
           $prd = 'charts/environments/prd/values.yaml';

           // Verifica se o diretório de destino existe
          if (!is_dir(dirname($int))) {
                // Cria o diretório de destino
                mkdir(dirname($int), 0777, true);
          }
          if (!is_dir(dirname($prd))) {
                // Cria o diretório de destino
                mkdir(dirname($prd), 0777, true);
         }

         if (copy($origem, $int)) {
                echo "[+] Arquivo copiado com sucesso. (int)\n";
        } else {
                echo '[-] Falha ao copiar o arquivo. (int)';
        }
        if (copy($origem, $prd)) {
                echo "[+] Arquivo copiado com sucesso. (prd)\n";
        } else {
                echo '[-] Falha ao copiar o arquivo. (prd)';
        }
}
?>
</body>
</html>
