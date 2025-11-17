local argokit = import '../argokit/jsonnet/argokit.libsonnet';

local ProbeHealthz = {
    path: "/healthz",
    port: 8080,
    failureThreshold: 3,
    timeout: 1,
    initialDelay: 0,
};
local ProbeReadyz = {
    path: "/readyz",
    port: 8080,
    failureThreshold: 3,
    timeout: 1,
    initialDelay: 0,
};

local BaseApp = {
    spec: {
        port: 8080,
        replicas: {
            min: 2,
            max: 5,
            targetCPUUtilization: 80,
        },
        liveness: ProbeHealthz,
        readiness: ProbeReadyz,
    },
};

[
    BaseApp + argokit.Application("foo-backend") {
        spec+: {
            image: "ghcr.io/skip-demo/skip-demo:latest",
            ingresses: ["skip-demo.atgcp1-sandbox.kartverket.no"],
    },
    }
]