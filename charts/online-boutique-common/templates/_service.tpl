{{- define "common.service" -}}
{{- if .Values.service.enabled -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ include "microservices-chart.namespace" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
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
  {{- fail "service.enabled=true but service.ports or single service port parameters are not defined" }}
  {{- end }}
{{- end }}
{{- end }}
