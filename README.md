# Demo: App på SKIP!

> Dette er et demo- og mal-repo som viser hvordan du pakker en applikasjon i en container med **Docker** og **GitHub Actions**, og ruller den ut på [**SKIP-plattformen**](https://skip.kartverket.no) ved hjelp av **ArgoKit**, **skipctl**, **Argo CD** og **Skiperator**.
>
> **💡 Språk- og rammeverksagnostisk:** Oppsettet i dette repoet er uavhengig av programmeringsspråk og rammeverk. Så lenge applikasjonen din kan pakkes i en container, kan du bruke denne repo-strukturen til å bygge og kjøre alt fra mikrotjenester, API-er og bakgrunnsjobber til frontend-applikasjoner på SKIP.

## Innhold

1. **Applikasjonskode (`app/`):** Mappen der selve kildekoden til applikasjonen ligger. Du står helt fritt til å velge programmeringsspråk og rammeverk – det eneste som kreves for en typisk web-applikasjon eller tjeneste på SKIP er at den lytter på en nettverksport (her `8080`) og tilbyr endepunkter for helsesjekker (`/healthz` og `/readyz`).
2. **Konteinerisering (`Dockerfile`):** En multi-stage `Dockerfile` som bygger applikasjonen fra `app/` og pakker den i et minimalt kjøretids-image som kjører som ikke-root bruker (`150:150`), i tråd med [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements).
3. **Kontinuerlig Integrasjon (CI):** En GitHub Actions-workflow (`.github/workflows/workflow.yaml`) som automatisk bygger `Dockerfile` og publiserer container-imaget til `ghcr.io` (GitHub Container Registry) ved hver push til `main`.
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
* En applikasjon som du ønsker å pakke i en container og kjøre på SKIP.

---

## Nødvendige verktøy (Windows, macOS og Linux)

Fordi applikasjonen bygges og kjøres i en container, trenger du kun noen få felles verktøy på maskinen din uavhengig av hvilket språk applikasjonen er skrevet i:

| Verktøy | Bruksområde | Påkrevd? |
| :--- | :--- | :--- |
| **Git** | Versjonskontroll og nedlasting av `argokit`-submodulen | Ja |
| **skipctl** | Rendre, formatere og validere Skiperator/Jsonnet-manifester lokalt | Ja |
| **Docker** (eller tilsvarende) | Bygge og kjøre container-imaget lokalt | Anbefalt |
| **Kodeeditor / IDE** | Valgfri editor (f.eks. VS Code, IntelliJ, Cursor e.l., gjerne med Jsonnet-plugin) | Anbefalt |

> **Tips:** `skipctl` har innebygd støtte for å evaluere og formatere Jsonnet-filer, så du trenger ikke å installere `jsonnet` separat for å validere eller rendre manifester.

### 🍎 macOS

På macOS anbefales det å bruke [Homebrew](https://brew.sh/):

```bash
# 1. Installer Git og Docker (eller OrbStack / Rancher Desktop)
brew install git
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
# 1. Installer Git og Docker (eksempel for Ubuntu/Debian)
sudo apt update
sudo apt install -y git docker.io

# 2. Installer skipctl (via Homebrew på Linux)
brew tap kartverket/taps
brew install skipctl
```

*Alternativt uten Homebrew:* Last ned siste Linux-versjon av `skipctl` direkte fra [GitHub Releases (`kartverket/skipctl`)](https://github.com/kartverket/skipctl/releases), gjør filen kjørbar (`chmod +x skipctl`) og flytt den til `/usr/local/bin/`.

### 🪟 Windows

På Windows kan du enten jobbe via **WSL2 (Windows Subsystem for Linux)** (anbefalt, følg da Linux-instruksjonene over) eller direkte i **PowerShell / Windows Terminal** med `winget`:

```powershell
# 1. Installer Git og Docker Desktop via winget
winget install --id Git.Git -e
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

### 2. Bygg og kjør containeren lokalt

Med Docker bygger og kjører du applikasjonen på akkurat samme måte uansett hvilket språk eller rammeverk som ligger i `app/`:

```bash
docker build -t skip-demo:local .
docker run --rm -p 8080:8080 skip-demo:local
```

Åpne deretter [http://localhost:8080](http://localhost:8080) i nettleseren for å teste applikasjonen! Helsesjekkene kan verifiseres på [http://localhost:8080/healthz](http://localhost:8080/healthz) og [http://localhost:8080/readyz](http://localhost:8080/readyz).

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

## 🚀 Lag din egen app og pakk den i en container!

Dette repoet er bygget opp som en generell mal du kan kopiere eller ta utgangspunkt i når du vil lage din egen applikasjon og rulle den ut på SKIP. SKIP krever ikke et bestemt programmeringsspråk eller rammeverk – kontrakten mellom applikasjonen din og plattformen er selve **containeren**.

### Repo-strukturen

Ved å følge strukturen i dette repoet får du et ryddig skille mellom **applikasjonskode**, **container-pakking**, **CI-bygging** og **SKIP-manifest**:

```text
mitt-app-repo/
├── app/                          # 💻 Kildekode, avhengigheter og ressurser for din applikasjon
├── Dockerfile                    # 📦 Oppskrift for å bygge og pakke app/ inn i et container-image
├── .github/
│   └── workflows/
│       └── workflow.yaml         # ⚙️ Bygger Dockerfile automatisk og pusher image til ghcr.io
├── manifestdemo/
│   └── app.jsonnet               # ☸️ ArgoKit-manifest som forteller Skiperator hvordan containeren skal kjøres
└── argokit/                      # 📚 Git-submodule med ArgoKit-biblioteket for lokal validering med skipctl
```

> **Tips:** GitHub Actions-workflowen i [`.github/workflows/workflow.yaml`](./.github/workflows/workflow.yaml) bruker `${{ github.repository }}` automatisk. Det betyr at hvis du oppretter et nytt repo med denne strukturen, vil workflowen automatisk bygge `Dockerfile` i rotmappen og publisere imaget til `ghcr.io/kartverket/<ditt-repo-navn>` uten at du trenger å endre workflow-filen!

### Steg 1: Legg inn din egen applikasjon i `app/`

Erstatt innholdet i [`app/`](./app) med din egen applikasjon, skrevet i det språket og rammeverket som passer oppgaven best. For at applikasjonen skal fungere godt i en container på SKIP, bør den oppfylle tre grunnleggende ting:

1. **Lytt på en uprivilegert port (f.eks. `8080`):** Applikasjonen må binde seg til en port over `1024` (f.eks. `0.0.0.0:8080`), siden containeren ikke kjører med `root`-rettigheter.
2. **Eksponer helsesjekk-endepunkter (`/healthz` og `/readyz`):** Lag endepunkter som returnerer HTTP `200 OK` når applikasjonen lever (*liveness*) og når den er klar til å ta imot trafikk (*readiness*).
3. **Konfigurasjon via miljøvariabler:** Les inn innstillinger og eventuelle hemmeligheter fra miljøvariabler, slik at samme container-image kan brukes på tvers av miljøer (lokalt, dev, test og prod).

### Steg 2: Pakk applikasjonen i en container (`Dockerfile`)

[`Dockerfile`](./Dockerfile) i rotmappen definerer hvordan koden i `app/` bygges og pakkes til et kjørbart container-image. Når du tilpasser `Dockerfile` til din applikasjon, bør du følge disse prinsippene for å oppfylle [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements):

1. **Bruk Multi-Stage Builds:**
   Del `Dockerfile` inn i et bygg-steg (`FROM <bygg-image> AS builder`) hvor kompilering, transpiling og nedlasting av avhengigheter skjer, og et eget kjøretids-steg til slutt som kun kopierer inn det ferdige resultatet (`COPY --from=builder ...`). Da blir container-imaget lite, raskt å rulle ut og inneholder færrest mulig sårbarheter.
2. **Velg et minimalt kjøretids-image:**
   Bruk et så slankt base-image som mulig i siste steg – for eksempel `scratch`, [Distroless](https://github.com/GoogleContainerTools/distroless) eller offisielle `-slim`/`-alpine`-varianter som kun inneholder selve kjøretidsmiljøet applikasjonen din trenger.
3. **Kjør som ikke-root bruker (`USER 150:150`):**
   Av sikkerhetshensyn tillater ikke SKIP at containere kjører som `root`. Legg alltid inn `USER 150:150` før `ENTRYPOINT`/`CMD` i siste steg av `Dockerfile`.
4. **Håndter skrivebeskyttet filsystem (`read-only root filesystem`):**
   På SKIP kjører containere med skrivebeskyttet rot-filsystem som standard. Applikasjonen bør derfor ikke forsøke å skrive filer direkte til arbeidsmappen under kjøring (bruk eventuelt minne, ekstern lagring eller et montert volum ved behov).
5. **Eksponer riktig port og startkommando:**
   Dokumenter porten med `EXPOSE 8080` og definer hvordan applikasjonen startes med `ENTRYPOINT` eller `CMD`.

### Steg 3: Tilpass manifestet (`manifestdemo/app.jsonnet`)

Oppdater applikasjonsnavn, image-referanse (`ghcr.io/kartverket/<ditt-repo>:...`), port og hostnavn i [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet), og valider lokalt med `skipctl manifest validate --path manifestdemo/app.jsonnet`.

---

## Fremgangsmåte: Fra kode til kjørende app på SKIP

1. **Utvikler/Applikasjonsdrifter:** Gjør en endring i applikasjonskoden i `app/`, eller endrer konfigurasjon som hostnavn, replikaer, CPU/minne e.l. i apps-repoet.
2. **Git Push / Pull Request:** Endringen merges til `main`-branchen.
3. **GitHub Actions (CI):**
   * Push til `main` trigger automatisk workflowen definert i `.github/workflows/workflow.yaml`.
   * Workflowen bygger et nytt container-image basert på `Dockerfile`.
   * Imaget tagges med commit-SHA og `latest`, og pushes til `ghcr.io/kartverket/<repo-navn>`.
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

* [`app/`](./app): Kildekoden til applikasjonen som skal kjøres på SKIP.
* [`Dockerfile`](./Dockerfile): Multi-stage oppskrift for å bygge applikasjonen i `app/` og pakke den til et minimalt, sikkert container-image.
* [`.github/workflows/workflow.yaml`](./.github/workflows/workflow.yaml): GitHub Actions-workflow som bygger `Dockerfile` og pusher container-imaget til GHCR.
* [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet): Eksempel på en Skiperator `Application`-ressurs skrevet med **ArgoKit v2**. *Merk: I en reell utrulling skal denne filen ligge i teamets apps-repo slik at den plukkes opp av Argo CD.*
* [`argokit/`](./argokit): [ArgoKit](https://github.com/kartverket/argokit)-repoet lagt til som en Git-submodule for tilgang til Jsonnet-bibliotekene i `argokit/v2`.
