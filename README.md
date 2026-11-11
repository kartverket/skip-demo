# Demo: App på SKIP!

> Dette er et demo- og startrepo som viser hvordan en applikasjon pakkes i en container med **Docker** og **GitHub Actions**, og deployeres til [**SKIP-plattformen**](https://skip.kartverket.no) ved hjelp av **ArgoKit**, **skipctl**, **Argo CD** og **Skiperator**.
>
> **💡 Bruk gjerne dette repoet som utgangspunkt for å lage dine egne applikasjoner!** Enten du vil bygge videre i Go, lage et eget spill eller verktøy i HTML/JS, eller skrive en app i et helt annet språk (Python, Node.js, Kotlin/Java, Rust, .NET osv.), kan du følge akkurat samme mappestruktur og container-oppsett for å få appen din raskt ut på SKIP.

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

## 🚀 Lag din egen app og pakk den i en container!

Dette repoet er bygget opp som en mal du kan kopiere eller ta utgangspunkt i når du vil lage din egen applikasjon og rulle den ut på SKIP. Så lenge applikasjonen din kan pakkes i en container og følger noen enkle konvensjoner, tar resten av oppsettet i repoet seg av bygging, publisering og utrulling!

### Repo-strukturen du kan følge

Ved å holde samme struktur som i dette repoet får du et ryddig skille mellom **applikasjonskode**, **container-pakking**, **CI-bygging** og **SKIP-manifest**:

```text
mitt-app-repo/
├── app/                          # 💻 Din applikasjonskode (Go, Python, Node, Kotlin, HTML/JS osv.)
│   ├── main.go                   #    Startpunkt for applikasjonen (inkl. /healthz og /readyz)
│   └── static/                   #    Statiske filer / frontend
├── Dockerfile                    # 📦 Oppskrift for å bygge og pakke app/ inn i et container-image
├── .github/
│   └── workflows/
│       └── workflow.yaml         # ⚙️ Bygger Dockerfile automatisk og pusher image til ghcr.io
├── manifestdemo/
│   └── app.jsonnet               # ☸️ ArgoKit-manifest som forteller Skiperator hvordan containeren skal kjøres
└── argokit/                      # 📚 Git-submodule med ArgoKit-biblioteket for lokal validering med skipctl
```

> **Tips:** GitHub Actions-workflowen i [`.github/workflows/workflow.yaml`](./.github/workflows/workflow.yaml) bruker `${{ github.repository }}` automatisk. Det betyr at hvis du oppretter et nytt repo med denne strukturen, vil workflowen automatisk bygge `Dockerfile` i rotmappen og publisere imaget til `ghcr.io/kartverket/<ditt-repo-navn>` uten at du trenger å endre workflow-filen!

### To måter å lage din egen app på

#### Alternativ 1: Bygg videre på Go-serveren eller bytt ut frontenden (Raskest!)
Hvis du vil lage en enkel web-app, et dashboard, et spill eller et lite API:
1. Bytt ut eller endre [`app/static/index.html`](./app/static/index.html) med din egen HTML/CSS/JavaScript-kode.
2. Legg eventuelt til nye API-ruter i [`app/main.go`](./app/main.go).
3. **Ingen endringer kreves i `Dockerfile`!** Kjør `docker build -t min-app:local .` for å pakke den nye appen din i en container.

#### Alternativ 2: Skriv en app i ditt favorittspråk i `app/`
SKIP bryr seg ikke om hvilket programmeringsspråk appen er skrevet i – så lenge den er pakket i en container:
1. Erstatt innholdet i [`app/`](./app) med ditt eget prosjekt (f.eks. Python med FastAPI/Flask, Node.js/TypeScript, Java/Kotlin, .NET eller Rust).
2. Sørg for at applikasjonen din starter en HTTP-server (f.eks. på port `8080`) og svarer med HTTP `200 OK` på helsesjekk-endepunktene `/healthz` og `/readyz`.
3. Oppdater [`Dockerfile`](./Dockerfile) slik at den bygger og pakker din applikasjon fra `./app`-mappen.

### 📦 Slik pakker du appen i en container for SKIP (`Dockerfile`-sjekkliste)

Når du lager eller tilpasser [`Dockerfile`](./Dockerfile) for din egen applikasjon, bør du følge mønsteret i dette repoet for å oppfylle [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements):

1. **Bruk Multi-Stage Builds:**
   Del `Dockerfile` inn i et bygg-steg (`FROM ... AS builder`) hvor kompilering og nedlasting av avhengigheter skjer, og et eget kjøretids-steg til slutt som kun kopierer inn det ferdige resultatet (`COPY --from=builder ...`). Da blir container-imaget lite, raskt å rulle ut og inneholder færrest mulig sårbarheter.
2. **Minimalt kjøretids-image:**
   * For kompilerte språk som **Go** eller **Rust**: Bruk `FROM scratch` eller `FROM gcr.io/distroless/static-debian12`.
   * For andre språk (**Node.js**, **Python**, **Java**, **.NET**): Bruk gjerne *distroless*-images (f.eks. `gcr.io/distroless/nodejs22-debian12`, `gcr.io/distroless/java21-debian12`) eller offisielle `-slim`/`-alpine`-varianter.
3. **Kjør som ikke-root bruker (`USER 150:150`):**
   Av sikkerhetshensyn tillater ikke SKIP at containere kjører som `root`. Legg alltid inn `USER 150:150` før `ENTRYPOINT`/`CMD` i siste steg av `Dockerfile`.
4. **Lytt på en uprivilegert port (f.eks. `8080`):**
   Siden containeren kjører som bruker `150`, har den ikke lov til å binde seg til porter under `1024` (som port `80`). Konfigurer appen til å lytte på f.eks. `8080`, dokumenter det med `EXPOSE 8080`, og bruk samme port i [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet).
5. **Husk at rot-filsystemet er skrivebeskyttet (`read-only`):**
   På SKIP kjører containere med skrivebeskyttet filsystem som standard. Appen din bør derfor ikke forsøke å skrive filer direkte til `/app`-mappen under kjøring.
6. **Tilpass manifestet (`manifestdemo/app.jsonnet`):**
   Oppdater applikasjonsnavn, image-referanse (`ghcr.io/kartverket/<ditt-repo>:...`), port og hostnavn i [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet), og valider med `skipctl manifest validate --path manifestdemo/app.jsonnet`.

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
