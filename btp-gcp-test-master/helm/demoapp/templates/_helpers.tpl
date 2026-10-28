{{/*
Expand the name of the chart.
*/}}
{{- define "demoapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
*/}}
{{- define "demoapp.fullname" -}}
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

{{- define "demoapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "demoapp.labels" -}}
helm.sh/chart: {{ include "demoapp.chart" . }}
{{ include "demoapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "demoapp.selectorLabels" -}}
app: {{ include "demoapp.fullname" . }}
app.kubernetes.io/name: {{ include "demoapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Fully qualified image reference.

Deployments are pinned by DIGEST, not tag: the promotion pipeline builds one
image on a feature branch and promotes that same digest through dev, staging and
prod. image.tag is only a fallback for local work and CI lint, and the render
fails if neither is supplied - an unqualified image would resolve to :latest.
*/}}
{{- define "demoapp.image" -}}
{{- $digest := default "" .Values.image.digest -}}
{{- if $digest -}}
{{- if not (hasPrefix "sha256:" $digest) -}}
{{- fail (printf "image.digest must start with sha256: (got %q)" $digest) -}}
{{- end -}}
{{- printf "%s/%s@%s" .Values.image.registry .Values.image.repository $digest -}}
{{- else -}}
{{- $tag := required "set image.digest (what the pipeline does) or image.tag (local/lint only)" .Values.image.tag -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag -}}
{{- end -}}
{{- end }}
