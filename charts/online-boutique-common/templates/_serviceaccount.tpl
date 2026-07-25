{{- define "common.serviceaccount" -}}
{{- $global := .Values.global | default dict -}}
{{- $gcp := $global.gcp | default dict -}}
{{- if and .Values.serviceAccount .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  namespace: {{ include "microservices-chart.namespace" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  annotations:
    {{- if $gcp.serviceAccountEmail }}
    iam.gke.io/gcp-service-account: {{ $gcp.serviceAccountEmail }}
    {{- end }}
{{- end }}
{{- end }}