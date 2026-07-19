{{- define "common.httproute" -}}
{{- $route := .Values.global.route | default .Values.route -}}
{{- if and $route $route.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $route.name | default (printf "%s-route" .Release.Name) }}
spec:
  parentRefs:
  - name: {{ $route.gatewayName | default "boutique-gateway" }}
  hostnames:
  - {{ $route.host | quote }}
  rules:
  - backendRefs:
    - name: {{ $route.serviceName | default "frontend" }}
      port: {{ $route.servicePort | default 80 }}
{{- end }}
{{- end }}