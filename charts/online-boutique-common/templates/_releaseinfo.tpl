{{- define "common.releaseinfo" -}}
{{- $releaseInfo := .Values.releaseInfo | default dict -}}
{{- if $releaseInfo.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.fullname" . }}-release-info
  namespace: {{ include "microservices-chart.namespace" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  chartName: {{ .Chart.Name | quote }}
  chartVersion: {{ .Chart.Version | quote }}
  releaseName: {{ .Release.Name | quote }}
  releaseNamespace: {{ include "microservices-chart.namespace" . | quote }}
  deployedAt: {{ now | date "2006-07-02T15:04:05Z" | quote }}
{{- end }}
{{- end }}