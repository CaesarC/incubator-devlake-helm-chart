{{/*
Expand the name of the chart.
*/}}
{{- define "devlake.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "devlake.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "devlake.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "devlake.labels" -}}
helm.sh/chart: {{ include "devlake.chart" . }}
{{ include "devlake.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "devlake.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devlake.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "devlake.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "devlake.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.grafanaEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/grafana" | replace "//" "/" | trimAll "/" -}}
{{- end }}

{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.uiEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/" | replace "//" "/" | trimAll "/" -}}
{{- end }}

{{/*
The ui endpoint
*/}}
{{- define "devlake.uiEndpoint" -}}
{{- if .Values.ingress.enabled }}
{{- $uiPortString := "" }}
{{- if .Values.ingress.enableHttps }}
{{- if ne 443 ( .Values.ingress.httpsPort | int) }}
{{- $uiPortString = printf ":%d" ( .Values.ingress.httpsPort | int) }}
{{- end }}
{{- printf "https://%s%s/%s" .Values.ingress.hostname $uiPortString (include "devlake.uiEndpointPrefix" .) }}
{{- else }}
{{- if ne 80 ( .Values.ingress.httpPort | int) }}
{{- $uiPortString = printf ":%d" ( .Values.ingress.httpPort | int) }}
{{- end }}
{{- printf "http://%s%s/%s" .Values.ingress.hostname $uiPortString (include "devlake.uiEndpointPrefix" .) }}
{{- end }}
{{- end }}
{{- end }}

{{- define "devlake.mysql.secret" -}}
{{- if .Values.option.connectionSecretName -}}
{{- .Values.option.connectionSecretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-db-connection
{{- end -}}
{{- end -}}

{{- define "devlake.ui.auth.secret" -}}
{{- if .Values.ui.basicAuth.secretName -}}
{{- .Values.ui.basicAuth.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-ui-auth
{{- end -}}
{{- end -}}

{{- define "devlake.lake.encryption.secret" -}}
{{- if .Values.lake.encryptionSecret.secretName -}}
{{- .Values.lake.encryptionSecret.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-encryption-secret
{{- end -}}
{{- end -}}

{{/*
The mysql server
*/}}
{{- define "mysql.server" -}}
{{- if .Values.mysql.useExternal }}
{{- .Values.mysql.externalServer }}
{{- else }}
{{- print (include "devlake.fullname" . ) "-mysql" }}
{{- end }}
{{- end }}


{{/*
The mysql port
*/}}
{{- define "mysql.port" -}}
{{- if .Values.mysql.useExternal }}
{{- .Values.mysql.externalPort }}
{{- else }}
{{- 3306 }}
{{- end }}
{{- end }}



{{/*
The database server
*/}}
{{- define "database.server" -}}
{{- if eq .Values.option.database "mysql" }}
{{- include "mysql.server" . }}
{{- end }}
{{- end }}


{{/*
The database port
*/}}
{{- define "database.port" -}}
{{- if eq .Values.option.database "mysql" }}
{{- include "mysql.port" . }}
{{- end }}
{{- end }}


{{/*
The database url
*/}}
{{- define "database.url" -}}
{{- if eq .Values.option.database "mysql" -}}
mysql://{{ .Values.mysql.username }}:{{ .Values.mysql.password }}@{{ include "mysql.server" . }}:{{ include "mysql.port" . }}/{{ .Values.mysql.database }}?charset=utf8mb4&parseTime=True&loc={{ .Values.commonEnvs.TZ }}
{{- end }}
{{- end }}


{{/*
The probe for check database connection
*/}}
{{- define "common.initContainerWaitDatabase" -}}
- name: waiting-database-ready
  image: "{{ .Values.alpine.image.repository }}:{{ .Values.alpine.image.tag }}"
  imagePullPolicy: {{ .Values.alpine.image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      until nc -z -w 2 {{ include "database.server" . }} {{ include "database.port" . }} ; do
        echo wait for database ready ...
        sleep 2
      done
      echo database is ready
{{- end }}


{{/*
Common image pull secrets
*/}}
{{- define "common.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common node selector
Usage: {{ include "common.nodeSelector" .Values.componentName | nindent 6 }}
*/}}
{{- define "common.nodeSelector" -}}
{{- with .nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common affinity
Usage: {{ include "common.affinity" .Values.componentName | nindent 6 }}
*/}}
{{- define "common.affinity" -}}
{{- with .affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common tolerations
Usage: {{ include "common.tolerations" .Values.componentName | nindent 6 }}
*/}}
{{- define "common.tolerations" -}}
{{- with .tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common pod security context
Usage: {{ include "common.podSecurityContext" .Values.componentName | nindent 6 }}
*/}}
{{- define "common.podSecurityContext" -}}
{{- with .securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common container security context
Usage: {{ include "common.containerSecurityContext" .Values.componentName | nindent 10 }}
*/}}
{{- define "common.containerSecurityContext" -}}
{{- with .containerSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common resources
Usage: {{ include "common.resources" .Values.componentName | nindent 10 }}
*/}}
{{- define "common.resources" -}}
{{- with .resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Common image configuration
Handles the image tag selection logic (component.image.tag or default imageTag)
Usage: {{ include "common.image" (dict "component" .Values.ui "defaultTag" .Values.imageTag) }}
*/}}
{{- define "common.image" -}}
{{- if .component.image.tag -}}
image: "{{ .component.image.repository }}:{{ .component.image.tag }}"
{{- else -}}
image: "{{ .component.image.repository }}:{{ .defaultTag }}"
{{- end -}}
{{- end }}


{{/*
Common environment variables from commonEnvs
Usage: {{ include "common.envs" . | nindent 12 }}
*/}}
{{- define "common.envs" -}}
{{- range $key, $value := .Values.commonEnvs }}
- name: "{{ tpl $key $ }}"
  value: "{{ tpl (print $value) $ }}"
{{- end }}
{{- end }}


{{/*
Ingress API version based on Kubernetes version
*/}}
{{- define "common.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end }}


{{/*
Ingress backend configuration based on Kubernetes version
Usage: {{ include "common.ingress.backend" (dict "context" $ "serviceName" $uiServiceName "servicePort" 4000) | nindent 14 }}
*/}}
{{- define "common.ingress.backend" -}}
{{- if semverCompare ">=1.19-0" .context.Capabilities.KubeVersion.GitVersion }}
service:
  name: {{ .serviceName }}
  port:
    number: {{ .servicePort }}
{{- else }}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- end }}
{{- end }}
