# Demo: App på SKIP!

> Dette er et demo-repo som viser hvordan en applikasjon pakkes med **GitHub Actions** og deployeres til **SKIP-plattformen** ved hjelp av **ArgoCD** og **Skiperator**.

## Innhold

1.  **Programvare:** En enkel applikasjon. (Go applikasjon som serverer statisk HTLM/JS)
2.  **Konteinerisering:** En `Dockerfile` som definerer hvordan appen pakkes i en kontainer.
3.  **Kontinuerlig Integrasjon (CI):** En GitHub Actions-workflow som bygger og pusher et Docker-image til ghcr.io (GitHub Container Registry) på hver push til `main`.
4.  **Kontinuerlig Leveranse (CD):**
    * [**ArgoKit**](https://github.com/kartverket/argokit) brukes for a template application-manifester m.m.
    * **ArgoCD** er satt opp til å overvåke endringer i [Apps repo.](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo)
    * **ArgoCD** pusher definert konfigurasjon til kubernetes clusteret. 
    * **Skiperator** (som kjører i clusteret) leser `Application`-manifestet.
    * **ArgoCD** synkroniserer manifestet, og Skiperator tar seg av selve utrullingen på SKIP-plattformen (oppretter Deployment, Service, Cert, osv.).


---


### 1. Forutsetninger

* Tilgang til SKIP som en del av et produktteam.
* Rettigheter i kartverkets Github
* Tilgang til et apps-repo.
* Tilkoblet kartverketes intranet for tilgang til [ArgoCD](https://argo-dev.kartverket.dev).
* En applikasjon som du ønsker å kjøre på skip.

---
## Fremgangsmåte

1.  **Utvikler/Applikasjonsdrifter:** Gjør en endring i applikasjonskoden. (ny funksjonalitet i koden, eller endring på hostnavn/minne/CPU e.l. i apps-repo)
2.  **Git Push:** Endringen pushes til `main`-branchen.
3.  **GitHub Actions (CI):**
    * Push trigger automatisk workflow definert i `.github/workflows/workflow.yaml`.
    * Workflow bygger et nytt Docker-image basert på `Dockerfile`.
    * Imaget tagges (f.eks. med `ghcr.io/ditt-navn/din-app:latest` eller med commit-SHA).
    * Workflow pusher det nye imaget til ghcr.
4.  **ArgoKit/skipctl:**
    * ArgoKit jasonnet template brukes for å lage applikasjons-manifestet, og [skipctl](https://github.com/kartverket/skipctl) brukes til validering av applikasjonsmanifestet. 
5.  **Synkronisering og Utrulling:**
    * ArgoCD ser den nye endringen i apps-repo og oppdaterer konfigurasjon ihht oppdateringer.
    * ArgoCD synkroniserer `Application`-manifestet til Kubernetes, enten automatisk, eller etter at noen har trykket "Sync" i argocd.
    * **Skiperator** oppdager endringen i `Application`-ressursen.
    * Skiperator genererer og oppdaterer de underliggende Kubernetes-ressursene (Deployment, Service, Ingress, etc.) for å matche den nye ønskede tilstanden.
    * Sertifikat oppretes og  rulles ut på SKIP.

---

## Nøkkelfiler i dette repoet

* `app/`: Kildekoden for selve demo-applikasjonen.
* `Dockerfile`: Oppskriften for å bygge applikasjonen inn i et container-image.
* `.github/workflows/workflow.yaml`: Definisjonen av github action som bygger og pusher imaget.
* `manifestdemo/app.jsonnet`: Det viktigste manifestet. Dette er `SKIPApplication`-ressursen som Skiperator leser. Det er *denne* filen ArgoCD bruker som sin "source of truth" for applikasjonen. Denne filen må ligge i et apps-repo for å kunne plukkes opp av 
* `argokit`-mappen er [ArgoKit](https://github.com/kartverket/argokit)-repoet sjekket ut som en submodule for å få tilgang til jsonnet bibliotekene.

---

