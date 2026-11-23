# Arbeidsflyt: fra kode til applikasjon på SKIP

Applikasjonskoden og utrullingsbeskrivelsen ligger i hvert sitt repo. Kode-repoet bygger og publiserer container-imaget, mens apps-repoet beskriver hvilken versjon som skal kjøre på SKIP.

```mermaid
flowchart LR
    subgraph source["Kode- og image-repo"]
        dev["Utvikler endrer app-kode eller Dockerfile"]
        sourceRepo["GitHub-repo med app/ og Dockerfile"]
        pr["Pull Request"]
        checks["GitHub Actions<br/>tester og bygg"]
        main["Push til main"]
        build["Bygg container-image<br/>tagget med commit-SHA"]
        pharos["Pharos skanner imaget"]
        deploy["deploy-jobb<br/>oppdaterer image-referansen"]
        dev --> sourceRepo
        sourceRepo --> pr --> checks
        sourceRepo --> main --> checks
        checks --> build
        build --> pharos
    end

    registry[("GitHub Container Registry<br/>ghcr.io/kartverket/&lt;repo&gt;")]

    subgraph apps["Teamets apps-repo"]
        manifest["app.jsonnet<br/>ArgoKit Application"]
        commit["Commit av ny image-tag"]
        argocd["Argo CD<br/>overvåker apps-repoet"]
        manifest --> commit --> argocd
    end

    subgraph skip["SKIP-cluster"]
        skiperator["Skiperator<br/>leser Application"]
        workload["Deployment og øvrige ressurser"]
        running["Kjørende applikasjon"]
        skiperator --> workload --> running
    end

    build -->|"publiserer image"| registry
    build --> deploy
    deploy -->|"oppdaterer Jsonnet-filen"| commit
    argocd -->|"synkroniserer manifest"| skiperator
    workload -->|"henter image"| registry
```

## Slik leser du flyten

1. På en Pull Request kjører GitHub Actions tester og bygger imaget som kontroll, men publiserer det ikke.
2. Når endringen merges til `main`, kjører workflowen test og bygg på nytt. Bygget image publiseres til GHCR med commit-SHA som tagg; `latest` oppdateres også.
3. Pharos skanner imaget. Deploy-jobben bruker Octo STS til å oppdatere image-taggen i `app.jsonnet` i teamets apps-repo, og committer endringen der.
4. Argo CD oppdager endringen i apps-repoet og synkroniserer Jsonnet-manifestet. ArgoKit gjør det om til en Skiperator `Application`.
5. Skiperator oppretter eller oppdaterer ressursene i clusteret. Workloaden henter det publiserte imaget fra GHCR.

Før automatisert deploy er aktivert, må `app.jsonnet` og ArgoKit være lagt inn i apps-repoet, og kode-repoet må ha `APPS_REPO`, `APPS_MANIFEST_PATH` og Octo STS-tillit konfigurert. Se [instruksjonene for apps-repoet i README](README.md#apps-repoet-slik-deployes-det-til-skip).
