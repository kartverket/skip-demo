local argokit = import '../argokit/v2/jsonnet/argokit.libsonnet';
local application = argokit.appAndObjects.application;

local livenessProbe = application.probe(
  path='/healthz',
  port=8080,
  failureThreshold=3,
  timeout=1,
  initialDelay=0,
);

local readinessProbe = application.probe(
  path='/readyz',
  port=8080,
  failureThreshold=3,
  timeout=1,
  initialDelay=0,
);

local image = 'ghcr.io/kartverket/skip-demo:latest';

application.new('skip-demo', image, 8080)
+ application.withRoutingProvider('Standard')
// Placeholder: <app>.<cluster>.kartverket-intern.cloud er kun tilgjengelig internt.
// Domener under kartverket.cloud åpnes mot internett (se sjekkliste før internetteksponering).
+ application.forHostnames('skip-demo.atkv3-dev.kartverket-intern.cloud')
+ application.withReplicas(
  initial=2,
  max=5,
  targetCpuUtilization=80,
)
// Retningslinjer for Kubernetes på SKIP: requests og limits skal settes på alle containere.
// Tommelfingerregel: minne-limit ca. 2x gjennomsnittlig bruk. Sett en fornuftig CPU-request.
// Juster etter faktisk forbruk i Grafana.
+ application.resources.withRequests(cpu='50m', memory='64Mi')
+ application.resources.withLimits(memory='128Mi')
// Konfigurasjon via miljøvariabler (appen leser PORT, se app/main.go).
+ application.withEnvironmentVariable('PORT', '8080')
+ application.withLiveness(livenessProbe)
+ application.withReadiness(readinessProbe)
// All trafikk til og fra appen er blokkert som standard (default deny). Appen under trenger
// ingen accessPolicy fordi den kun nås via ingress. Trenger du kommunikasjon mellom tjenester:
//   + application.withInboundSkipApp(appname='annen-app', namespace='annet-namespace')
//   + application.withOutboundSkipApp(appname='backend', namespace='backend-namespace')
// Se https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/configuring
