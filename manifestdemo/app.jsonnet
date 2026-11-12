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

application.new('skip-demo', 'ghcr.io/kartverket/skip-demo:latest', 8080)
+ application.withRoutingProvider('Standard')
+ application.forHostnames('skip-demo.eksempel.kartverket.cloud')
+ application.withReplicas(
  initial=2,
  max=5,
  targetCpuUtilization=80,
)
+ application.withLiveness(livenessProbe)
+ application.withReadiness(readinessProbe)
