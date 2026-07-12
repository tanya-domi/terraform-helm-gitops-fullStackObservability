{{- define "common.configmap" -}}
{{- /* 1. Define the safe global variable */ -}}
{{- $global := .Values.global | default dict -}}
{{- /* 2. Create sub-dicts to prevent deep-nesting crashes */ -}}
{{- $services := $global.services | default dict -}}
{{- $redis := $global.redis | default dict -}}
{{- $features := $global.features | default dict -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $global.configMapName | default "common-config" }}
  namespace: {{ .Release.Namespace }}
data:
  REDIS_ADDR: {{ $redis.address | default "" | quote }}
  PRODUCT_CATALOG_SERVICE_ADDR: {{ $services.productcatalogservice | default "" | quote }}
  CURRENCY_SERVICE_ADDR: {{ $services.currencyservice | default "" | quote }}
  CART_SERVICE_ADDR: {{ $services.cartservice | default "" | quote }}
  RECOMMENDATION_SERVICE_ADDR: {{ $services.recommendationservice | default "" | quote }}
  SHIPPING_SERVICE_ADDR: {{ $services.shippingservice | default "" | quote }}
  CHECKOUT_SERVICE_ADDR: {{ $services.checkoutservice | default "" | quote }}
  AD_SERVICE_ADDR: {{ $services.adservice | default "" | quote }}
  ENABLE_PROFILER: {{ $features.profiler_enabled | default "false" | quote }}
{{- end -}}

