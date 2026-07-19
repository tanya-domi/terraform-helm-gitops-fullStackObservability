{{- define "common.gateway" -}}
{{- $gateway := .Values.global.gateway | default .Values.gateway -}}
{{- if and $gateway $gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: {{ $gateway.name | default (printf "%s-gateway" .Release.Name) }}
spec:
  gatewayClassName: {{ $gateway.className | default "gke-l7-gylb" }}
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: {{ $gateway.host | quote }}
    tls:
      mode: Terminate
      certificateRefs:
      {{- range $gateway.certificates }}
      - name: {{ . }}
        kind: Secret # Or ManagedCertificate if using GKE specific types
      {{- end }}
{{- end }}
{{- end }}