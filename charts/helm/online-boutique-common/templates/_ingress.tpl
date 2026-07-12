{{- define "common.ingress" -}}
{{- $ingress := .Values.global.ingress | default .Values.ingress -}}
{{- if and $ingress $ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $ingress.name | default (printf "%s-ingress" .Release.Name) }}
  annotations:
{{- with $ingress.annotations }}
{{ toYaml . | nindent 4 }}
{{- end }}
spec:
{{- if $ingress.className }}
  ingressClassName: {{ $ingress.className }}
{{- end }}
  rules:
    - host: {{ $ingress.host | quote }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $ingress.serviceName | default "frontend" }}
                port:
                  number: {{ $ingress.servicePort | default 80 }}
{{- end }}
{{- end }}
