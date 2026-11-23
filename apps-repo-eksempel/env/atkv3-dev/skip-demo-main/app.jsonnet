local argokit = import '../../../argokit/v2/jsonnet/argokit.libsonnet';
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
+ application.forHostnames('skip-demo.atkv3-dev.kartverket-intern.cloud')
+ application.withReplicas(
  initial=2,
  max=5,
  targetCpuUtilization=80,
)
+ application.resources.withRequests(cpu='50m', memory='64Mi')
+ application.resources.withLimits(memory='128Mi')
+ application.withEnvironmentVariable('PORT', '8080')
+ application.withLiveness(livenessProbe)
+ application.withReadiness(readinessProbe)
