<script src="https://unpkg.com/@opentelemetry/api@1.9.0/dist/sidecar/otls.js"></script> <script src="https://unpkg.com/@opentelemetry/api@1.9.0/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/resources@1.25.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/semantic-conventions@1.25.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/sdk-trace-base@1.25.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/sdk-trace-web@1.25.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/exporter-trace-otlp-http@0.52.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/instrumentation@0.52.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/instrumentation-fetch@0.52.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/instrumentation-xml-http-request@0.52.1/build/umd/index.min.js"></script>
<script src="https://unpkg.com/@opentelemetry/context-zone@1.25.1/build/umd/index.min.js"></script>

<script>
  const { Resource } = opentelemetry.resources;
  const { SemanticResourceAttributes } = opentelemetry.semanticConventions;
  const { WebTracerProvider } = opentelemetry.sdkTraceWeb;
  const { BatchSpanProcessor } = opentelemetry.sdkTraceBase;
  const { OTLPTraceExporter } = opentelemetry.exporterTraceOtlpHttp;
  const { FetchInstrumentation } = opentelemetry.instrumentationFetch;
  const { XMLHttpRequestInstrumentation } = opentelemetry.instrumentationXmlHttpRequest;
  const { registerInstrumentations } = opentelemetry.instrumentation;
  const { ZoneContextManager } = opentelemetry.contextZone;

  const exporter = new OTLPTraceExporter({
  url: "/v1/traces" 
});

  const provider = new WebTracerProvider({
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: "frontend-browser",
    }),
  });

  provider.addSpanProcessor(new BatchSpanProcessor(exporter));
  provider.register({
    contextManager: new ZoneContextManager()
  });

  registerInstrumentations({
    instrumentations: [
      new FetchInstrumentation({
        propagateTraceHeaderCorsUrls: [/.*/] // This links browser spans to Go backend spans
      }),
      new XMLHttpRequestInstrumentation()
    ],
  });
</script>


// mothod 1 . Using ES Module import syntax

// import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
// import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
// import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
// // etc...
// Cons
// Requires a build step: Online Boutique frontend is a Go server serving static HTML/JS

// Method 2. Using UMD <script> tags (via CDN)

// <script src="https://unpkg.com/@opentelemetry/sdk-trace-web@1.25.1/build/umd/index.min.js"></script>
// <script src="https://unpkg.com/@opentelemetry/exporter-trace-otlp-http@0.52.1/build/umd/index.min.js"></script>
// <script>
//   const { WebTracerProvider } = opentelemetry.sdkTraceWeb;
//   const { BatchSpanProcessor } = opentelemetry.sdkTraceBase;
//   const { OTLPTraceExporter } = opentelemetry.exporterTraceOtlpHttp;
//   // ...
// </script>

// Pros
// No build step required

// Recommendation for Online Boutique frontend
// Use the UMD <script> approach:

// Enable Trace Correlation (Critical)
// To connect browser spans → backend spans, you must allow trace headers.
// Backend (frontend service) must allow
// traceparent
// tracestate

// For Go HTTP servers: Access-Control-Allow-Headers: traceparent,tracestate,content-type
// // Without this, service maps will not connect.

// // 
// npm install \
//   @opentelemetry/api \
//   @opentelemetry/sdk-trace-web \
//   @opentelemetry/exporter-trace-otlp-http \
//   @opentelemetry/instrumentation-fetch \
//   @opentelemetry/instrumentation-xml-http-request


// How Online Boutique Frontend Is Structured (Key Fact)
// frontend/ is a Go HTTP server
// HTML is rendered from templates
// Static assets are served from /static
// There is no package.json and no JS build pipeline
// You must add browser OTEL via static JS assets (bundled or CDN), not npm inside the service.

// Option(Recommended): Use a Bundled Static JS File (No npm)
// This is the simplest and safest approach.
