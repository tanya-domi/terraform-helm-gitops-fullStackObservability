{{- define "common.deployment" -}}
{{- $global := .Values.global | default dict -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ include "microservices-chart.namespace" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
      {{- with .Values.annotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" . }}

      {{- with .Values.image.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000

      {{- with .Values.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      containers:
        {{- range .Values.containers }}
        - name: {{ .name }}
          image: "{{ $.Values.image.repository }}:{{ $.Values.image.tag }}"
          imagePullPolicy: {{ $.Values.image.pullPolicy | default "IfNotPresent" }}

          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL

          {{- with .ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          env:
            {{- /* 1. Render container-specific envs if defined locally */ -}}
            {{- with .env }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

            {{- /* 2. Inject static chart-level environment variables */ -}}
            {{- if $.Values.env }}
            - name: ENVIRONMENT
              value: {{ $.Values.env | quote }}
            {{- end }}

            {{- /* 3. Inject Global Feature Flags from ConfigMap/Globals */ -}}
            {{- if and $global.features $global.configMapName (eq .name "server") }}
            - name: ENABLE_PROFILER
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: ENABLE_PROFILER
            {{- end }}

            {{- /* 4. Dynamically inject Cross-Service DNS Addrs from global.services */ -}}
            {{- if and $global.services (eq .name "server") }}
            {{- if $global.services.productcatalogservice }}
            - name: PRODUCT_CATALOG_SERVICE_ADDR
              value: {{ $global.services.productcatalogservice | quote }}
            {{- end }}
            {{- if $global.services.currencyservice }}
            - name: CURRENCY_SERVICE_ADDR
              value: {{ $global.services.currencyservice | quote }}
            {{- end }}
            {{- if $global.services.cartservice }}
            - name: CART_SERVICE_ADDR
              value: {{ $global.services.cartservice | quote }}
            {{- end }}
            {{- if $global.services.recommendationservice }}
            - name: RECOMMENDATION_SERVICE_ADDR
              value: {{ $global.services.recommendationservice | quote }}
            {{- end }}
            {{- if $global.services.shippingservice }}
            - name: SHIPPING_SERVICE_ADDR
              value: {{ $global.services.shippingservice | quote }}
            {{- end }}
            {{- if $global.services.checkoutservice }}
            - name: CHECKOUT_SERVICE_ADDR
              value: {{ $global.services.checkoutservice | quote }}
            {{- end }}
            {{- if $global.services.adservice }}
            - name: AD_SERVICE_ADDR
              value: {{ $global.services.adservice | quote }}
            {{- end }}
            {{- end }}

          {{- with .livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with .readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with .resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        {{- end }}
{{- end }}