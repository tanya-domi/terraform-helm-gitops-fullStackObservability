{{- define "common.service" -}}
{{- if .Values.service.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.serviceName }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.appLabel }}
    job: {{ .Values.jobLabel }}
  annotations:
    {{- if .Values.service.annotations }}
    {{- toYaml .Values.service.annotations | nindent 4 }}
    {{- end }}
spec:
  selector:
    app: {{ .Values.appLabel }}
  type: {{ .Values.service.type | default "ClusterIP" }}

  {{- if .Values.service.ports }}
  ports:
    {{- range .Values.service.ports }}
    - name: {{ .name }}
      protocol: TCP
      port: {{ .port }}
      targetPort: {{ .targetPort }}
    {{- end }}
  {{- else if and .Values.service.name .Values.service.port .Values.service.targetPort }}
  ports:
    - name: {{ .Values.service.name }}
      protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  {{- else }}
  {{- fail "service.enabled=true but service.ports is not defined for this microservice" }}
  {{- end }}

{{- else }}
# Service creation skipped because service.enabled=false
{{- end }}
{{- end }}

