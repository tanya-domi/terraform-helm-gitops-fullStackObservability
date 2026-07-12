{{- define "common.deployment" -}}
{{- $global := .Values.global | default dict -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deploymentName }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.appLabel }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
  template:
    metadata:
      labels:
        app: {{ .Values.appLabel }}
      annotations:
        {{- with .Values.annotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}

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
          imagePullPolicy: {{ $.Values.image.pullPolicy }}

          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL

          {{- with .ports }}
          ports:
            {{- range . }}
            - containerPort: {{ .containerPort }}
            {{- end }}
          {{- end }}

          {{- if or .env $global.configMapName }}
          env:
            {{- if .env }}
            {{- range .env }}
            - name: {{ .name }}
              value: "{{ .value }}"
            {{- end }}
            {{- end }}

            {{- if $global.configMapName }}
            - name: ENABLE_PROFILER
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: ENABLE_PROFILER
            {{- end }}

            {{- if $.Values.env }}
              {{- if $.Values.env.productcatalogservice }}
            - name: PRODUCT_CATALOG_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: PRODUCT_CATALOG_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.currencyservice }}
            - name: CURRENCY_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: CURRENCY_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.cartservice }}
            - name: CART_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: CART_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.recommendationservice }}
            - name: RECOMMENDATION_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: RECOMMENDATION_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.shippingservice }}
            - name: SHIPPING_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: SHIPPING_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.checkoutservice }}
            - name: CHECKOUT_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: CHECKOUT_SERVICE_ADDR
              {{- end }}

              {{- if $.Values.env.adservice }}
            - name: AD_SERVICE_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: AD_SERVICE_ADDR
              {{- end }}
              {{- if and $global.redis $global.redis.address }}
            - name: REDIS_ADDR
              valueFrom:
                configMapKeyRef:
                  name: {{ $global.configMapName }}
                  key: REDIS_ADDR
              {{- end }}
            {{- end }}
          {{- end }}

          {{- with .livenessProbe }}
          livenessProbe:
            initialDelaySeconds: {{ .initialDelaySeconds | default 5 }}
            periodSeconds: {{ .periodSeconds | default 10 }}
            timeoutSeconds: {{ .timeoutSeconds | default 1 }}
            failureThreshold: {{ .failureThreshold | default 3 }}
            {{- if .httpGet }}
            httpGet:
              path: {{ .httpGet.path }}
              port: {{ .httpGet.port }}
              {{- with .httpGet.httpHeaders }}
              httpHeaders:
                {{- toYaml . | nindent 16 }}
              {{- end }}
            {{- else if .grpc }}
            grpc:
              port: {{ .grpc.port }}
              {{- if .grpc.service }}
              service: {{ .grpc.service }}
              {{- end }}
            {{- else if .tcpSocket }}
            tcpSocket:
              port: {{ .tcpSocket.port }}
            {{- end }}
          {{- end }}

          {{- with .readinessProbe }}
          readinessProbe:
            initialDelaySeconds: {{ .initialDelaySeconds | default 5 }}
            periodSeconds: {{ .periodSeconds | default 10 }}
            timeoutSeconds: {{ .timeoutSeconds | default 1 }}
            failureThreshold: {{ .failureThreshold | default 3 }}
            {{- if .httpGet }}
            httpGet:
              path: {{ .httpGet.path }}
              port: {{ .httpGet.port }}
              {{- with .httpGet.httpHeaders }}
              httpHeaders:
                {{- toYaml . | nindent 16 }}
              {{- end }}
            {{- else if .grpc }}
            grpc:
              port: {{ .grpc.port }}
              {{- if .grpc.service }}
              service: {{ .grpc.service }}
              {{- end }}
            {{- end }}
          {{- end }}

          {{- with .resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        {{- end }}
{{- end }}
