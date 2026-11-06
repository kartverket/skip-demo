# Demo: App på SKIP!

> Dette er et demo-repo som viser hvordan en applikasjon pakkes med **Docker** og **GitHub Actions**, og deployeres til [**SKIP-plattformen**](https://skip.kartverket.no) ved hjelp av **ArgoKit**, **skipctl**, **Argo CD** og **Skiperator**.

## Innhold

1. **Programvare (`app/`):** En enkel Go-applikasjon (med [Gin](https://github.com/gin-gonic/gin)) som serverer et Snake-spill i statisk HTML/JS på port `8080`, samt helsesjekk-endepunkter (`/healthz` og `/readyz`).
2. **Konteinerisering (`Dockerfile`):** En multi-stage `Dockerfile` som kompilere applikasjonen til en statisk binærfil og pakker den i et minimalt `scratch`-image som kjører som bruker `150:150` (i tråd med [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements)).
3. **Kontinuerlig Integrasjon (CI):** En GitHub Actions-workflow (`.github/workflows/workflow.yaml`) som bygger og pusher et container-image til `ghcr.io` (GitHub Container Registry) ved hver push til `main`.
4. **Kontinuerlig Leveranse (CD):**
   * [**ArgoKit v2**](https://skip.kartverket.no/docs/applikasjon-utrulling/argokit/getting-started) brukes for å definere applikasjonsmanifestet i Jsonnet (`manifestdemo/app.jsonnet`).
   * [**skipctl**](https://skip.kartverket.no/docs/applikasjon-utrulling/skipctl/get-started) brukes til å rendre, formatere og validere manifestet mot kjente Kubernetes- og Skiperator-skjemaer.
   * [**Argo CD**](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/komme-i-gang-med-argocd) overvåker endringer i teamets [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) og synkroniserer konfigurasjonen til Kubernetes-clusteret.
   * [**Skiperator**](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator) (som kjører i clusteret) leser `Application`-manifestet og oppretter de underliggende Kubernetes-ressursene (Deployment, Service, ruting/ingress, nettverkspolicyer, sertifikater osv.).

---

## Forutsetninger på SKIP

* Tilgang til SKIP som en del av et produktteam (se [Kom i gang på SKIP](https://skip.kartverket.no/docs/kom-i-gang)).
* Rettigheter i Kartverkets GitHub-organisasjon.
* Tilgang til et [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) satt opp mot Argo CD.
* Tilkoblet Kartverkets intranett/VPN for tilgang til [Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd).
* En applikasjon som du ønsker å kjøre på SKIP.

---

## Nødvendige verktøy (Windows, macOS og Linux)

For å jobbe med applikasjonen og manifestene lokalt trenger du følgende verktøy installert på maskinen din:

| Verktøy | Bruksområde | Påkrevd? |
| :--- | :--- | :--- |
| **Git** | Versjonskontroll og nedlasting av `argokit`-submodulen | Ja |
| **skipctl** | Rendre, formatere og validere Skiperator/Jsonnet-manifester lokalt | Ja |
| **Docker** (eller tilsvarende) | Bygge og kjøre container-imaget lokalt | Anbefalt |
| **Go** (1.25+) | Bygge og kjøre Go-applikasjonen direkte på egen maskin | Valgfritt (kun ved lokal Go-utvikling) |
| **Kodeeditor / IDE** | F.eks. [VS Code](https://code.visualstudio.com/) eller GoLand/IntelliJ (gjerne med Go- og Jsonnet-plugins) | Anbefalt |

> **Tips:** `skipctl` har innebygd støtte for å evaluere og formatere Jsonnet-filer, så du trenger ikke å installere `jsonnet` separat for å validere eller rendre manifester.

### 🍎 macOS

På macOS anbefales det å bruke [Homebrew](https://brew.sh/):

```bash
# 1. Installer Git, Go og Docker (eller OrbStack / Rancher Desktop)
brew install git go
brew install --cask docker

# 2. Installer skipctl fra Kartverkets Homebrew-tap
brew tap kartverket/taps
brew install skipctl

# Sjekk at skipctl er installert
skipctl -v
```

For å oppdatere `skipctl` senere:
```bash
brew upgrade kartverket/taps/skipctl
```

### 🐧 Linux

På Linux kan du bruke din distribusjons pakkebehandler (f.eks. `apt` på Ubuntu/Debian eller `dnf` på Fedora) i kombinasjon med [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) eller nedlasting av binærfil fra GitHub:

```bash
# 1. Installer Git, Go og Docker (eksempel for Ubuntu/Debian)
sudo apt update
sudo apt install -y git golang-go docker.io

# 2. Installer skipctl (via Homebrew på Linux)
brew tap kartverket/taps
brew install skipctl
```

*Alternativt uten Homebrew:* Last ned siste Linux-versjon av `skipctl` direkte fra [GitHub Releases (`kartverket/skipctl`)](https://github.com/kartverket/skipctl/releases), gjør filen kjørbar (`chmod +x skipctl`) og flytt den til `/usr/local/bin/`.

### 🪟 Windows

På Windows kan du enten jobbe via **WSL2 (Windows Subsystem for Linux)** (anbefalt, følg da Linux-instruksjonene over) eller direkte i **PowerShell / Windows Terminal** med `winget`:

```powershell
# 1. Installer Git, Go og Docker Desktop via winget
winget install --id Git.Git -e
winget install --id GoLang.Go -e
winget install --id Docker.DockerDesktop -e
```

**Installere `skipctl` på Windows:**
1. Gå til [GitHub Releases for `skipctl`](https://github.com/kartverket/skipctl/releases) og last ned siste versjon for Windows (`skipctl_Windows_x86_64.zip`).
2. Pakk ut `skipctl.exe` og legg filen i en mappe som ligger i systemets `PATH`-miljøvariabel.
3. Verifiser installasjonen i PowerShell:
   ```powershell
   skipctl -v
   ```

---

## Kom i gang lokalt

### 1. Klon repoet og last ned `argokit`-submodulen

Fordi dette repoet inkluderer [ArgoKit](https://github.com/kartverket/argokit) som en Git-submodule, må submodulen initialiseres:

```bash
# Klon repoet inkludert submodules:
git clone --recurse-submodules https://github.com/kartverket/skip-demo.git
cd skip-demo

# Eller hvis du allerede har klonet repoet på vanlig måte:
git submodule update --init --recursive
```

### 2. Kjør applikasjonen lokalt

**Alternativ A – Med Docker:**
```bash
docker build -t skip-demo:local .
docker run --rm -p 8080:8080 skip-demo:local
```

**Alternativ B – Direkte med Go:**
```bash
cd app
go run .
```

Åpne deretter [http://localhost:8080](http://localhost:8080) i nettleseren for å spille Snake! Helsesjekkene kan testes på [http://localhost:8080/healthz](http://localhost:8080/healthz) og [http://localhost:8080/readyz](http://localhost:8080/readyz).

### 3. Rendre og validere manifestet med `skipctl`

Du kan teste at Jsonnet-manifestet i `manifestdemo/app.jsonnet` kompilerer og er gyldig før du legger det inn i et apps-repo:

```bash
# Se det ferdig rendrede Kubernetes/Skiperator-manifestet:
skipctl manifest render --path manifestdemo/app.jsonnet

# Valider manifestet mot Kubernetes- og Skiperator-skjemaer:
skipctl manifest validate --path manifestdemo/app.jsonnet

# Formater Jsonnet-filen:
skipctl manifest format --path manifestdemo/app.jsonnet
```

---

## Fremgangsmåte: Fra kode til kjørende app på SKIP

1. **Utvikler/Applikasjonsdrifter:** Gjør en endring i applikasjonskoden (f.eks. ny funksjonalitet i `app/`), eller endrer konfigurasjon som hostnavn, replikaer, CPU/minne e.l. i apps-repoet.
2. **Git Push / Pull Request:** Endringen merges til `main`-branchen.
3. **GitHub Actions (CI):**
   * Push til `main` trigger automatisk workflowen definert i `.github/workflows/workflow.yaml`.
   * Workflowen bygger et nytt container-image basert på `Dockerfile`.
   * Imaget tagges med commit-SHA og `latest`, og pushes til `ghcr.io/kartverket/skip-demo`.
4. **ArgoKit og `skipctl`:**
   * ArgoKit v2 Jsonnet-malen (`manifestdemo/app.jsonnet`) brukes for å definere `Application`-manifestet.
   * `skipctl manifest validate` brukes for å verifisere at manifestet er gyldig.
5. **Apps-repo:**
   * Teamets [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) oppdateres med det validerte applikasjonsmanifestet.
6. **Synkronisering og utrulling:**
   * **Argo CD** oppdager endringen i apps-repoet og synkroniserer `Application`-manifestet til Kubernetes-clusteret (automatisk eller ved manuell "Sync" i Argo CD).
   * **Skiperator** oppdager endringen i `Application`-ressursen og genererer/oppdaterer de underliggende Kubernetes-ressursene (Deployment, Service, Gateway API-ruting, NetworkPolicy osv.).
   * Sertifikat opprettes automatisk og applikasjonen er tilgjengelig på sitt konfigurerte domene.

---

## Nøkkelfiler i dette repoet

* [`app/`](./app): Kildekoden for selve demo-applikasjonen (Go + statisk HTML/JS).
* [`Dockerfile`](./Dockerfile): Multi-stage oppskrift for å bygge applikasjonen til et minimalt `scratch` container-image.
* [`.github/workflows/workflow.yaml`](./.github/workflows/workflow.yaml): GitHub Actions-workflow som bygger og pusher container-imaget til GHCR.
* [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet): Eksempel på en Skiperator `Application`-ressurs skrevet med **ArgoKit v2**. *Merk: I en reell utrulling skal denne filen ligge i teamets apps-repo slik at den plukkes opp av Argo CD.*
* [`argokit/`](./argokit): [ArgoKit](https://github.com/kartverket/argokit)-repoet lagt til som en Git-submodule for tilgang til Jsonnet-bibliotekene i `argokit/v2`.
