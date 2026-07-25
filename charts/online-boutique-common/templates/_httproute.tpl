{{- define "common.httproute" -}}
{{- $global := .Values.global | default dict -}}
{{- $gateway := $global.gateway | default .Values.gateway -}}
{{- if and $gateway $gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  parentRefs:
    - name: {{ $gateway.gatewayName | default "boutique-gateway" }}
      namespace: {{ $gateway.gatewayNamespace | default "platform" }}
  hostnames:
    - "{{ $gateway.host }}"
  rules:
    - backendRefs:
        - name: {{ include "common.fullname" . }}
          port: {{ .Values.service.port | default 80 }}
{{- end }}
{{- end }}