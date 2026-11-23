# Demo: App på SKIP!

> Dette er et demo- og mal-repo som viser hvordan du pakker en applikasjon i en container med **Docker** og **GitHub Actions**, og ruller den ut på [**SKIP-plattformen**](https://skip.kartverket.no) ved hjelp av **ArgoKit**, **skipctl**, **Argo CD** og **Skiperator**.
>
> Demo-appen i dette repoet er skrevet i Go. I hovedløypa bruker du den som den er, slik at du kan konsentrere deg om bygging, publisering og utrulling. Senere kan du bytte den ut med en applikasjon i et annet språk eller rammeverk, så lenge den kan pakkes i et Linux-containerimage.

## Mål for workshopen

**Målet er at du oppretter ditt eget repo i GitHub-organisasjonen [`kartverket`](https://github.com/kartverket) og ruller ut demo-appen til SKIP derfra.** Du bruker den ferdige appen og containeroppsettet i dette repoet, og lærer hvordan koden bygges, imaget publiseres og appen deployes. Å lage eller ta med en egen applikasjon er en ekstraoppgave.

Følg [Opprette nytt repo på GitHub](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/opprette-nytt-repo-p%C3%A5-github) når du oppretter repoet:

* Sett **Owner** til `kartverket`, ikke din private bruker.
* Velg visibility, her er det både lov å velge **public** og **private**.
* **Ikke velg lisens** med mindre det er et reelt open source-prosjekt.
* Legg inn en [`CODEOWNERS`](./.github/CODEOWNERS)-fil med ditt eget team, og gi teamet tilgang til repoet.
* Gi repoet et navn som er et gyldig appnavn (små bokstaver og bindestrek). Workflowen publiserer imaget til `ghcr.io/kartverket/<repo-navn>`.

## Workshopløype

Følg stegene i rekkefølge: test demoen lokalt, opprett kildekode-repoet, klargjør apps-repoet, og publiser og verifiser utrullingen. Du bruker demo-appen og Dockerfile som de er; å lage en egen app er en ekstraoppgave. Se [arbeidsflytdiagrammet](./ARBEIDSFLYT.md) for hvordan repoene og SKIP henger sammen.

1. [Kjør demoen lokalt](#1-kjør-demoen-lokalt)
2. [Opprett kildekode-repoet](#2-opprett-kildekode-repoet)
3. [Klargjør apps-repoet](#3-klargjør-apps-repoet)
4. [Publiser og rull ut](#4-publiser-og-rull-ut)

`app/` inneholder demo-appens kildekode, `Dockerfile` pakker den som et container-image, og GitHub Actions bygger og publiserer imaget til GHCR. Et `Application`-manifest i teamets apps-repo beskriver hvordan Skiperator skal kjøre appen. Argo CD synkroniserer manifestet til clusteret.

---

## Forutsetninger på SKIP

* Tilgang til SKIP som en del av et produktteam (se [Kom i gang på SKIP](https://skip.kartverket.no/docs/kom-i-gang)).
* Rettigheter i Kartverkets GitHub-organisasjon.
* Tilgang til et [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) satt opp mot Argo CD.
* Tilkoblet Kartverkets intranett/VPN for tilgang til [Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd).
* Du trenger ikke ha en egen applikasjon klar. Workshopens hovedløype bruker demo-appen som følger med dette repoet.

## Kompetansekrav

For å få godt utbytte av denne demoen bør du ha:

* **Grunnleggende kjennskap til terminal og Git:** Kunne kjøre kommandoer i terminalen, klone et repo og gjøre vanlige Git-operasjoner (`commit`, `push`, Pull Requests) mot GitHub.
* **Grunnleggende forståelse av containere (Docker/Podman):** Vite hva en `Dockerfile` og et container-image er, og hvordan en applikasjon bygges og kjøres i en container.
* **Grunnleggende forståelse av nettverk og HTTP:** Kjennskap til konsepter som nettverksporter, miljøvariabler og HTTP-endepunkter (f.eks. for helsesjekker).
* **Overordnet kjennskap til CI/CD og GitOps (en fordel):** Grunnleggende forståelse av automatisert bygging (GitHub Actions) og deklarative konfigurasjonsfiler. Du trenger *ikke* inngående forkunnskaper om Kubernetes eller Jsonnet, da **Skiperator** og **ArgoKit** abstraherer bort det meste av kompleksiteten.

> **Trenger du en oppfriskning?** Se [`Jukselappen.md`](Jukselappen.md) for en enkel jukselapp med de vanligste kommandoene i terminalen, Git, Docker, Podman og `skipctl`.

---

## Nødvendige verktøy (Windows, macOS og Linux)

Fordi applikasjonen bygges og kjøres i en container, trenger du kun noen få felles verktøy på maskinen din uavhengig av hvilket språk applikasjonen er skrevet i:

| Verktøy | Bruksområde | Påkrevd? |
| :--- | :--- | :--- |
| **Git** | Versjonskontroll og nedlasting av `argokit`-submodulen | Ja |
| **skipctl** | Rendre, formatere og validere Skiperator/Jsonnet-manifester lokalt | Ja |
| **Docker** (eller tilsvarende, f.eks. Colima, OrbStack eller Podman) | Bygge og kjøre container-imaget lokalt | Ja (for å teste containeren lokalt) |
| **GitHub CLI (`gh`)** | Opprette repo fra terminalen. Kan også gjøres i nettleseren | Valgfritt |
| **Kodeeditor / IDE** | Valgfri editor (f.eks. VS Code, IntelliJ, Cursor e.l., gjerne med Jsonnet-plugin) | Anbefalt |

> **Tips:** `skipctl` har innebygd støtte for å evaluere og formatere Jsonnet-filer, så du trenger ikke å installere `jsonnet` separat for å validere eller rendre manifester.

### macOS

På macOS anbefales det å bruke [Homebrew](https://brew.sh/):

```bash
# 1. Installer Git og en container-runtime. Colima er gratis og gir docker-kommandoen.
#    (Docker Desktop krever betalt lisens, se Windows-avsnittet under. OrbStack og Podman Desktop er alternativer.)
brew install git colima docker
colima start

# 2. Installer skipctl fra Kartverkets Homebrew-tap
brew tap kartverket/taps
brew trust kartverket/taps
brew install skipctl

# Sjekk at skipctl er installert
skipctl -v
```

For å oppdatere `skipctl` senere:
```bash
brew upgrade kartverket/taps/skipctl
```

### Linux

På Linux kan du bruke din distribusjons pakkebehandler (f.eks. `apt` på Ubuntu/Debian eller `dnf` på Fedora) i kombinasjon med [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) eller nedlasting av binærfil fra GitHub:

```bash
# 1. Installer Git og Docker (eksempel for Ubuntu/Debian)
sudo apt update
sudo apt install -y git docker.io
sudo usermod -aG docker "$USER"   # gjør at du kan kjøre docker uten sudo (logg ut og inn igjen etterpå)

# 2. Installer skipctl (via Homebrew på Linux)
brew tap kartverket/taps
brew trust kartverket/taps
brew install skipctl
```

*Alternativt uten Homebrew:* Last ned siste Linux-versjon av `skipctl` direkte fra [GitHub Releases (`kartverket/skipctl`)](https://github.com/kartverket/skipctl/releases), gjør filen kjørbar (`chmod +x skipctl`) og flytt den til `/usr/local/bin/`.

### Windows

På administrerte Windows-maskiner har man normalt ikke lokale administratorrettigheter som standard, og fordi Docker Desktop krever betalt lisens brukes **Podman Desktop** på Windows. For å installere utviklerverktøy må du enten:
* **Installere via virksomhetens programvareportal:** Sjekk først om verktøyene du trenger (f.eks. Git, VS Code, WSL, Podman Desktop e.l.) ligger tilgjengelig for selvbetjent installasjon på maskinen din.
* **Elevere til administratorrettigheter ved behov:** Hvis et verktøy ikke ligger i programvareportalen, eller installasjonen krever utvidede rettigheter (f.eks. ved bruk av `winget`, oppsett av WSL2/Podman eller endring av systemets `PATH`), må du først aktivere midlertidige administratorrettigheter på maskinen.

Når du jobber på Windows kan du enten bruke **WSL2 (Windows Subsystem for Linux)** (anbefalt, følg da Linux-instruksjonene over inne i WSL-terminalen) eller jobbe direkte i **PowerShell / Windows Terminal** med **Podman Desktop** (bruk da `podman` i stedet for `docker` når du bygger og kjører containere).

**Installere Git og Podman Desktop via `winget`:**
```powershell
# Kjøres med eleverte rettigheter dersom påkrevd:
winget install --id Git.Git -e
winget install --id RedHat.Podman -e
winget install --id RedHat.Podman-Desktop -e

# Initialiser og start Podman-maskinen (kan også gjøres i Podman Desktop):
podman machine init
podman machine start
```

**Installere `skipctl` på Windows:**
1. Gå til [GitHub Releases for `skipctl`](https://github.com/kartverket/skipctl/releases) og last ned siste versjon for Windows (`skipctl_Windows_x86_64.zip`).
2. Pakk ut `skipctl.exe` og legg filen i en mappe som ligger i din `PATH`-miljøvariabel (du kan legge til en egen mappe i brukerens *User PATH* uten administratorrettigheter, eller elevere rettigheter for å legge den i systemets `PATH`).
3. Verifiser installasjonen i en ny PowerShell-terminal:
   ```powershell
   skipctl -v
   ```

---

## 1. Kjør demoen lokalt

Start med å klone demo-repoet, kjøre appen lokalt og validere eksempelmanifestet. Deretter går du videre til [steg 2](#2-opprett-kildekode-repoet) og oppretter ditt eget kildekode-repo.

> **Før du starter:** Git må være satt opp mot GitHub med Kartverket-kontoen din. Følg [Autentisering til GitHub i terminalen](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/autentisering-til-github-i-terminalen) (SSH-nøkkel som er godkjent med *Configure SSO*), sett `user.name` og `user.email`, og sett opp signerte commits (se [`Jukselappen.md`](Jukselappen.md#2-git-versjonskontroll)). Å klone dette demo-repoet fungerer uten innlogging, men du trenger det for å pushe til ditt eget repo.

### 1. Klon demo-repoet og last ned `argokit`-submodulen

Fordi dette repoet inkluderer [ArgoKit](https://github.com/kartverket/argokit) som en Git-submodule, må submodulen initialiseres:

```bash
# Klon repoet inkludert submodules:
git clone --recurse-submodules https://github.com/kartverket/skip-demo.git
cd skip-demo

# Eller hvis du allerede har klonet repoet på vanlig måte:
git submodule update --init --recursive
```

Sjekk at `argokit/` ikke er tom (`ls argokit`). Hvis den er tom feiler `skipctl` senere med `couldn't open import "argokit/..."`.

### 2. Bygg og kjør containeren lokalt

Bygg og kjør Go-demoappen lokalt med samme sikkerhetskontekst som Skiperator bruker på SKIP (UID/GID `150`, ingen capabilities, skrivebeskyttet rot-filsystem der kun `/tmp` er skrivbart), slik at du oppdager problemer før du deployer:

```bash
docker build -t skip-demo:local .
docker run --rm --read-only --tmpfs /tmp --user 150:150 --cap-drop ALL \
  --security-opt no-new-privileges -p 8080:8080 skip-demo:local
```

> **Podman (Windows):** bruk `podman` i stedet for `docker`. I PowerShell erstatter du linjeskiftet `\` med backtick (`` ` ``) eller skriver kommandoen på én linje.

`-p 8080:8080` kobler porten din maskin lytter på til porten applikasjonen lytter på i containeren (`<host-port>:<container-port>`, se `EXPOSE` i `Dockerfile`). Åpne [http://localhost:8080](http://localhost:8080) i nettleseren, eller test fra en ny terminal:

```bash
curl -i http://localhost:8080/healthz
curl -i http://localhost:8080/readyz
```

Begge skal svare `200 OK`. Stopp containeren med `Ctrl+C`. Hvis porten er opptatt, se [`Jukselappen.md`](Jukselappen.md#5-vanlige-feilmeldinger-og-løsninger).

### 3. Rendre og validere manifestet med `skipctl`

Du kan teste at Jsonnet-manifestet i `manifestdemo/app.jsonnet` kompilerer og er gyldig før du legger det inn i et apps-repo:

```bash
# Se det ferdig rendrede Kubernetes/Skiperator-manifestet:
skipctl manifest render --path manifestdemo/app.jsonnet

# Valider manifestet mot Kubernetes- og Skiperator-skjemaer (laster ned skjemaene, så du må ha nettilgang):
skipctl manifest validate --path manifestdemo/app.jsonnet

```

Se hvordan resultatet av `render` henger sammen med `manifestdemo/app.jsonnet`: appnavn, image, ingress, replikaer, ressurser og helsesjekker i Jsonnet blir til `spec` i Skiperator-`Application`.

---

## 2. Opprett kildekode-repoet

Nå som du har sett at demoen virker, lager du ditt eget repo i [`kartverket`](https://github.com/kartverket)-organisasjonen. Bruk reglene fra [Mål for workshopen](#mål-for-workshopen).

**1. Opprett repoet** i nettleseren (*+ → New repository*, Owner `kartverket`, ønsket synlighet, ingen lisens), eller med GitHub CLI:

```bash
gh repo create kartverket/<mitt-app-navn> --private --clone
cd <mitt-app-navn>
```

Eksempelet oppretter et privat repo; bruk `--public` hvis du valgte offentlig synlighet. Opprettet du repoet i nettleseren, klon det (se [autentisering](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/autentisering-til-github-i-terminalen)) og gå inn i mappen.

**2. Kopier demoappen og utrullingsoppsettet inn i repoet.** I hovedløypa lar du `app/` og `Dockerfile` være uendret. Fra mappen til ditt nye repo, med demoen klonet ved siden av (`../skip-demo`):

```bash
cp -r ../skip-demo/app ../skip-demo/Dockerfile ../skip-demo/.dockerignore \
      ../skip-demo/.github ../skip-demo/manifestdemo .
```

Kopier *ikke* `.git` eller `argokit/` fra demoen. `argokit` legger du til som submodule i neste steg. På Windows gjør du dette i WSL, eller med `Copy-Item -Recurse` i PowerShell.

**3. Legg til `argokit` som submodule** ([installasjonsguide](https://skip.kartverket.no/docs/applikasjon-utrulling/argokit/installation-guide)):

```bash
git submodule add https://github.com/kartverket/argokit.git
```

**4. Tilpass repo- og teamdetaljer.** Sett ditt eget team i `.github/CODEOWNERS`. GitHub Actions bruker repo-navnet automatisk når det bygger imaget. `manifestdemo/app.jsonnet` er et lokalt eksempel som valideres av workflowen; selve utrullingsmanifestet tilpasser du i apps-repoet i steg 3. Bruk søket under for å finne andre forekomster av `skip-demo` du eventuelt må oppdatere:

```bash
grep -rn "skip-demo" . --exclude-dir=.git --exclude-dir=argokit --exclude=README.md
```

Repoet er nå klart for demoappen. Fortsett til steg 3 for å legge utrullingsmanifestet i apps-repoet. Du trenger ikke endre applikasjonskoden eller Dockerfile i hovedløypa.

---

## 3. Klargjør apps-repoet

Kildekode-repoet bygger imaget, mens teamets [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) beskriver hva som skal kjøre på SKIP. I denne workshopen holder du repoene adskilt og legger Jsonnet-manifestet i apps-repoet. Å samle manifest og kildekode i ett repo er også en støttet konfigurasjon, men som bør avtales med SKIP. Mappen [`apps-repo-eksempel/`](./apps-repo-eksempel) viser strukturen:

```text
apps-repo-eksempel/
├── .github/chainguard/
│   └── skip-demo.sts.yaml            # Valgfritt: Octo STS-tillit for CI-deploy (ekstraoppgave)
├── env/
│   └── atkv3-dev/                    # Cluster: atkv3-dev, atkv3-prod, atgcp1-dev eller atgcp1-prod
│       └── skip-demo-main/           # Namespace. Må starte med teamets prefiks (f.eks. appnavnet)
│           ├── app.jsonnet           # Skiperator Application definert med ArgoKit
│           └── config.json           # Valgfritt: tool, autoSync, prune, selfHeal
└── argokit/                          # ArgoKit Git-submodule som Jsonnet-manifestet importerer
```

* **Namespace** opprettes automatisk av Argo CD når mappen dukker opp. Prefikset avtales med SKIP når apps-repoet settes opp ([Komme i gang med Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/komme-i-gang-med-argocd)).
* **`config.json`** styrer synkroniseringen ([dokumentasjon](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/configuring-apps-repositories-with-configjson)). Auto-sync er på som standard i dev, men av i prod.
* SKIP dokumentasjonen bruker ofte YAML direkte i apps-repo for å forenkle. Denne workshopen bruker likevel Jsonnet for å introdusere ArgoKit og gjenbrukbar konfigurasjon. Se [SKIPs ArgoKit-guide](https://skip.kartverket.no/docs/applikasjon-utrulling/argokit/getting-started).

### Opprett og valider manifestet

Gjør dette i teamets apps-repo. ArgoKit-submodulen legges til én gang per apps-repo; manifestet legges til for hver app:

1. Fra roten av apps-repoet, legg til ArgoKit hvis den ikke allerede finnes:
   ```bash
   git submodule add https://github.com/kartverket/argokit.git
   ```
2. Opprett manifestmappen og kopier `manifestdemo/app.jsonnet` fra kildekode-repoet. Eksempel fra roten av apps-repoet:
   ```bash
   mkdir -p env/<cluster>/<namespace>
   cp ../<kildekode-repo>/manifestdemo/app.jsonnet env/<cluster>/<namespace>/app.jsonnet
   ```
   Oppdater importstien til `../../../argokit/v2/jsonnet/argokit.libsonnet`. Cluster og namespace velges gjennom mappestien.
3. I `app.jsonnet`, tilpass appnavn, hostnavn og image. Sett image til `ghcr.io/kartverket/<repo-navn>:latest` for første utrulling.
4. Valider fra roten av apps-repoet:
   ```bash
   skipctl manifest validate --path env/<cluster>/<namespace>/app.jsonnet
   ```
   Bruk eventuelt `skipctl manifest render --path env/<cluster>/<namespace>/app.jsonnet` for å inspisere resultatet. Det er Jsonnet-filen som skal sjekkes inn.
5. Commit og push manifestet til apps-repoet etter teamets vanlige review-prosess. Argo CD synkroniserer manifestet; om auto-sync er av, må noen velge **Sync** i Argo CD.

Image-oppdatering fra GitHub Actions er en ekstraoppgave. I hovedløypa oppdaterer du image-referansen manuelt etter at imaget er publisert (steg 4). Se ekstraoppgaven [Automatiser image-oppdateringen](#oppgave-b-automatiser-image-oppdateringen-i-apps-repoet) hvis du vil sette opp Octo STS og CI-deploy.

> **Rollback:** Argo CD har innebygd rollback (*History and rollback*), men imaget må fortsatt finnes i GHCR. Se [Hvordan bruke Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hvordan-bruke-argocd). Feilsøking: [Troubleshooting på SKIP](https://skip.kartverket.no/docs/kom-i-gang/troubleshoot/troubleshooting-on-skip).

---

## 4. Publiser og rull ut

Når kildekode-repoet og apps-repoet er klargjort, publiser demoen:

1. Opprett en branch i kildekode-repoet, commit oppsettet og push branchen. Repoer i organisasjonen krever signerte commits (se [`Jukselappen.md`](Jukselappen.md#2-git-versjonskontroll)).

   ```bash
   git switch -c oppsett
   git add .
   git commit -m "Sett opp demoapp for utrulling"
   git push -u origin oppsett
   ```

2. Åpne en Pull Request og sjekk workflowen under **Actions**. Den bygger imaget som kontroll, men publiserer det ikke før endringen merges til `main`.
3. Når PR-en er godkjent, merge den til `main`. GitHub Actions bygger og publiserer imaget til GHCR; Pharos skanner det.
4. Finn commit-SHA-en for bygget, og endre `local image`-verdien i apps-repoets `app.jsonnet` til `ghcr.io/kartverket/<repo-navn>:sha-<full-commit-SHA>`. Commit og push endringen etter teamets review-prosess.
5. Sjekk at imaget finnes under **Packages**, at Argo CD viser applikasjonen som *Synced* og *Healthy*, og at appen svarer på HTTPS-adressen. Hvis auto-sync er av, synkroniser i Argo CD.
6. Gå gjennom [sjekklisten](#sjekkliste-dette-skal-du-ha-laget).

---

## Sjekkliste: dette skal du ha laget

Når du er ferdig med hovedløypa, skal følgende stemme:

- [ ] Du har opprettet et eget repo i GitHub-organisasjonen `kartverket` (public eller private, uten lisens), med `CODEOWNERS` og tilgang for teamet ditt.
- [ ] Demoappen i `app/` svarer 200 på `/healthz` og `/readyz`, lytter på `PORT` (standard `8080`) og stopper pent på SIGTERM.
- [ ] `docker build` fungerer, og containeren kjører med `--read-only --tmpfs /tmp --user 150:150 --cap-drop ALL`.
- [ ] `Dockerfile` er multi-stage, bruker et egnet runtime-image, har `USER 150:150` og `EXPOSE`.
- [ ] GitHub Actions bygger og pusher til `ghcr.io/kartverket/<repo>` ved push til `main`.
- [ ] `skipctl manifest validate` er grønn for manifestet, og `resources`, probes, `routingProvider: Standard` og ingress er satt.
- [ ] Jsonnet-manifestet ligger i apps-repoet under `env/<cluster>/<namespace>/`, og Argo CD viser appen som *Synced* og *Healthy*.
- [ ] Appen svarer på ingress-hostnavnet over HTTPS.

---

## Referanse: app, container og manifest

Hovedløypa krever ikke at du endrer appen eller Dockerfile. Bruk denne delen som oppslag hvis du vil forstå strukturen bedre eller gjøre ekstraoppgaven med en egen app.

### Repo-struktur

```text
mitt-app-repo/
├── app/                          # Kildekode, avhengigheter og tester
├── Dockerfile                    # Bygger og pakker app/ til et container-image
├── .dockerignore
├── .github/
│   ├── CODEOWNERS
│   └── workflows/                # Bygger, publiserer og skanner
├── manifestdemo/
│   └── app.jsonnet               # Lokalt eksempel for validering
└── argokit/                      # Git-submodule for Jsonnet og skipctl
```

`apps-repo-eksempel/` i dette repoet viser strukturen til et separat apps-repo; den mappen kopieres ikke til kildekode-repoet. GitHub Actions bruker `${{ github.repository }}` og publiserer imaget til `ghcr.io/kartverket/<repo-navn>`.

### App og container

Kildekoden i [`app/`](./app) er en enkel Go-webapp. Den lytter på `PORT` (standard `8080`), svarer på `/healthz` og `/readyz`, og håndterer SIGTERM. [`Dockerfile`](./Dockerfile) bygger og pakker appen; du trenger ikke endre den i hovedløypa.

SKIPs [krav til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements) er at appen er containerisert og imaget publiseres til et register clusteret har tilgang til. Workloads følger [retningslinjene for Kubernetes](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/kubernetes/retningslinjer-for-kubernetes) og Pod Security Standards nivå *restricted*. Hvis du tilpasser Dockerfile:

1. Bruk gjerne Multi-Stage Build for å holde runtime-imaget lite.
2. SKIP anbefaler [Docker Hardened Images (DHI)](https://www.docker.com/products/hardened-images/); velg et runtime-image som inneholder det appen trenger.
3. Kjør som UID/GID `150:150` (`USER 150:150`) slik at containeren oppfører seg likt lokalt og på SKIP.
4. Håndter skrivebeskyttet rot-filsystem. Appen kan skrive til `/tmp`; test lokalt med `docker run --read-only --tmpfs /tmp --user 150:150 ...`. Trenger appen mer skriveplass, konfigurer et volum eller objektlagring etter relevant veiledning.
5. Dokumenter porten med `EXPOSE` og definer startkommando med `ENTRYPOINT` eller `CMD`.

### Manifest

`manifestdemo/app.jsonnet` er et lokalt ArgoKit-eksempel. Det faktiske utrullingsmanifestet ligger i apps-repoet. Hostnavn følger vanligvis mønsteret `<app>.<cluster>.kartverket-intern.cloud` for intern tilgang eller `<app>.<cluster>.kartverket.cloud` for internettilgang. Se [URLer og sertifikat for tjenester på SKIP](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/kubernetes/urler-og-sertifikat-for-tjenester-p%C3%A5-skip) og [sjekklisten før interneteksponering](https://skip.kartverket.no/docs/applikasjon-utrulling/sjekkliste-f%C3%B8r-internett-eksponering).

Sett `requests` og `limits` for CPU og minne på alle containere. Demo-manifestet bruker `50m` CPU / `64Mi` minne som request og `128Mi` minne som limit; juster etter faktisk forbruk.

---

## Ekstraoppgave: Bytt ut demoappen med din egen

Når du har fått demoappen til å kjøre på SKIP, kan du erstatte innholdet i `app/` med en egen applikasjon. Du kan bruke et annet språk eller rammeverk, men appen må kunne pakkes i et Linux-containerimage og oppfylle plattformens krav. Oppdater og test Dockerfile, CI-workflowene og manifestet ved behov. Appen må fortsatt lytte på porten manifestet angir, og implementere helsesjekkene som manifestet bruker. Se [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements) og [anbefalingene for containeren](#app-og-container).

---

## Ekstraoppgave: Bygg ut GitHub Actions-oppsettet

*For deg som er ferdig med resten tidlig.* Repoet har allerede en solid grunnkonfigurasjon i `.github/`. Les gjennom den først, den er ment som en mal du kan ta med deg til egne repoer. Se også [GitHub Actions på SKIP](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions).

| Fil | Hva den gjør | Dokumentasjon |
| :--- | :--- | :--- |
| [`workflow.yaml`](./.github/workflows/workflow.yaml) | Bygger og pusher image til GHCR og kjører Pharos etter push til `main` | [GitHub Actions](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions) og [Pharos](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/pharos) |
| [`validate-manifest.yaml`](./.github/workflows/validate-manifest.yaml) | Kjører `skipctl manifest validate` når manifestet endres i en PR | [skipctl manifester](https://skip.kartverket.no/docs/applikasjon-utrulling/skipctl/manifests) |
| [`dependency-review.yaml`](./.github/workflows/dependency-review.yaml) | Kommenterer sårbarheter og lisensproblemer i endrede avhengigheter på PR-er | [Dependency review](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/dependency-review) |
| [`dependabot.yml`](./.github/dependabot.yml) | Daglige PR-er for `argokit`-submodulen, GitHub Actions, Docker-imaget og Go-modulen | [Dependabot](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/dependabot) |

Alle actions er pinnet til commit-SHA med versjonen som kommentar, og hver jobb har minst mulig `permissions`. Dependabot holder SHA-ene oppdatert.

Lag en egen branch og én Pull Request per oppgave, slik at du får testet at workflowene kjører på `pull_request` før du merger til `main`. Feilsøk i **Actions**-fanen på GitHub.

### Oppgave A: Skann imaget hver natt

Pharos skanner i dag bare imaget som akkurat er bygget. Nye sårbarheter oppdages også i imager som ikke er endret, så SKIP anbefaler å skanne [minst én gang i døgnet](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/pharos).

* [ ] Lag `.github/workflows/pharos-nightly.yaml` som kjører på `schedule` (`cron`) og skanner `ghcr.io/<repo>:latest`.
* [ ] Gi jobben permissions `actions: read`, `packages: read`, `contents: read` og `security-events: write`.
* [ ] Legg til `workflow_dispatch:` slik at du kan kjøre den manuelt for å teste.
* [ ] Sjekk resultatene under **Security → Code scanning**.

### Oppgave B: Automatiser image-oppdateringen i apps-repoet

I hovedløypa oppdaterer du image-referansen manuelt. Utvid workflowen slik at et push til `main` også oppdaterer apps-repoet etter at imaget er publisert. SKIP beskriver mønsteret i [Deploye automatisk ved push](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo#deploye-automatisk-ved-push), og tilgang med kortlevd token i [Octo STS-veiledningen](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/tilgang-til-repoer-med-tokens-fra-github-actions).

* [ ] Legg Octo STS-tillit i apps-repoet, og konfigurer `APPS_REPO` og `APPS_MANIFEST_PATH` som Actions-variabler i kildekode-repoet.
* [ ] Legg til en deploy-jobb som henter kortlevd token, sjekker ut apps-repoet, endrer `local image`-verdien til imaget med commit-SHA, og committer/pusher endringen.
* [ ] Bekreft at Argo CD synkroniserer den nye image-referansen.

### Oppgave C: Semver-tagger ved release

I dag får imaget kun taggene `sha-<commit>` og `latest`. Legg til støtte for versjonerte releaser.

* [ ] Trigg `workflow.yaml` også på `push` av tags som matcher `v*.*.*`.
* [ ] Legg til `type=semver,pattern={{version}}` i `docker/metadata-action` og sørg for at `latest` fortsatt kun settes på `main`.
* [ ] Lag en tag (`git tag v0.1.0 && git push --tags`) og sjekk at riktige tagger dukker opp under **Packages**.
* [ ] Tenk gjennom: hva bør `pharos`-jobben (som i dag kun kjører på `main`) gjøre ved tag-bygg?

### Oppgave D (utfordring): Eget namespace per branch, med opprydding

Etter at [Oppgave B](#oppgave-b-automatiser-image-oppdateringen-i-apps-repoet) er løst, kan du utvide deploy-jobben slik at den også kjører for andre branches enn `main` og kopierer manifestet til `env/<cluster>/<prefiks>-<branch>/`. Lag deretter en `on: delete`-workflow som fjerner mappen igjen når branchen slettes, slik at du ikke bruker opp clusterkapasitet. Se eksemplene nederst i [Hva er et apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo#deploye-automatisk-ved-push). Obs: eksemplet i dokumentasjonen bruker `kubectl patch --local ... -o yaml`, som kun skriver til stdout og ikke endrer filen. Bruk `yq -i` eller omdiriger output. Hostnavnet i manifestet må også være unikt per branch.

### Oppgave E: Gjør `skipctl` tilgjengelig som eget steg

`validate-manifest.yaml` laster ned `skipctl` med en fast versjon. Utvid den slik at den også:

* [ ] Kjører `skipctl manifest render --path manifestdemo/app.jsonnet` og laster opp resultatet som artifact (`actions/upload-artifact`), slik at reviewere kan se det ferdige YAML-manifestet.
* [ ] Sjekker at Jsonnet-filen er formatert (`skipctl manifest format` etterfulgt av `git diff --exit-code`).

---

## Nøkkelfiler i dette repoet

* [`app/`](./app): Kildekoden til applikasjonen som skal kjøres på SKIP.
* [`Dockerfile`](./Dockerfile): Multi-stage oppskrift for å bygge applikasjonen i `app/` og pakke den til et minimalt, sikkert container-image.
* [`.github/workflows/`](./.github/workflows): GitHub Actions-workflows for bygg og push til GHCR ([`workflow.yaml`](./.github/workflows/workflow.yaml)), Pharos-skanning, manifestvalidering og dependency review.
* [`apps-repo-eksempel/`](./apps-repo-eksempel): Eksempel på apps-repo-strukturen (`env/<cluster>/<namespace>/`, `config.json` og valgfri Octo STS-tillit).
* [`.github/dependabot.yml`](./.github/dependabot.yml): Automatiske oppdateringer av `argokit`, GitHub Actions, Docker-imaget og Go-avhengigheter.
* [`.github/CODEOWNERS`](./.github/CODEOWNERS): Hvilket team som eier repoet. Bytt ut teamet når du bruker repoet som mal.
* [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet): Eksempel på en Skiperator `Application`-ressurs skrevet med **ArgoKit v2**. *Merk: I en reell utrulling skal denne filen ligge i teamets apps-repo slik at den plukkes opp av Argo CD.*
* [`argokit/`](./argokit): [ArgoKit](https://github.com/kartverket/argokit)-repoet lagt til som en Git-submodule for tilgang til Jsonnet-bibliotekene i `argokit/v2`.
* [`Jukselappen.md`](Jukselappen.md): Oppslagsverk og jukselapp med grunnleggende kommandoer for terminal, Git, Docker, Podman og `skipctl`.
