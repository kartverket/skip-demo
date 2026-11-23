# Demo: App på SKIP!

> Dette er et demo- og mal-repo som viser hvordan du pakker en applikasjon i en container med **Docker** og **GitHub Actions**, og ruller den ut på [**SKIP-plattformen**](https://skip.kartverket.no) ved hjelp av **ArgoKit**, **skipctl**, **Argo CD** og **Skiperator**.
>
> **Språk- og rammeverksagnostisk:** Oppsettet i dette repoet er uavhengig av programmeringsspråk og rammeverk. Så lenge applikasjonen din kan pakkes i en container, kan du bruke denne repo-strukturen til å bygge og kjøre alt fra mikrotjenester, API-er og bakgrunnsjobber til frontend-applikasjoner på SKIP.

## Mål for workshopen

**Målet er at du oppretter ditt eget repo i GitHub-organisasjonen [`kartverket`](https://github.com/kartverket)**, med en fungerende app som bygges, pakkes i en container og rulles ut på SKIP, på samme måte som dette repoet gjør det. Dette repoet er fasit og mal: bruk det som utgangspunkt, men bygg det opp i ditt eget repo.

Følg [Opprette nytt repo på GitHub](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/opprette-nytt-repo-p%C3%A5-github) når du oppretter repoet:

* Sett **Owner** til `kartverket`, ikke din private bruker.
* Velg visibility, her er det både lov å velge **public** og **private**.
* **Ikke velg lisens** med mindre det er et reelt open source-prosjekt.
* Legg inn en [`CODEOWNERS`](./.github/CODEOWNERS)-fil med ditt eget team, og gi teamet tilgang til repoet.
* Gi repoet et navn som er et gyldig appnavn (små bokstaver og bindestrek). Workflowen publiserer imaget til `ghcr.io/kartverket/<repo-navn>`.

Se [Sjekkliste: dette skal du ha laget](#sjekkliste-dette-skal-du-ha-laget) for å verifisere at du er i mål.

## Innhold

1. **Applikasjonskode (`app/`):** Mappen der selve kildekoden til applikasjonen ligger. Du står helt fritt til å velge programmeringsspråk og rammeverk. Det eneste som kreves for en typisk web-applikasjon eller tjeneste på SKIP er at den lytter på en nettverksport (her `8080`) og tilbyr endepunkter for helsesjekker (`/healthz` og `/readyz`).
2. **Konteinerisering (`Dockerfile`):** En multi-stage `Dockerfile` som bygger applikasjonen fra `app/` og pakker den i et minimalt kjøretids-image som kjører som ikke-root bruker (`150:150`), i tråd med [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements) og [retningslinjene for Kubernetes på SKIP](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/kubernetes/retningslinjer-for-kubernetes) (Pod Security Standards nivå *restricted*).
3. **Kontinuerlig Integrasjon (CI):** GitHub Actions-workflows i `.github/workflows/` som kjører Go-tester, bygger `Dockerfile` og publiserer container-imaget til `ghcr.io` (GitHub Container Registry) ved hver push til `main` (på Pull Requests bygges imaget kun for å verifisere at bygget går gjennom, uten å pushe). I tillegg skannes imaget med Pharos, avhengigheter kontrolleres (dependency review og Dependabot), og manifestet valideres med `skipctl`.
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
* En applikasjon som du ønsker å pakke i en container og kjøre på SKIP. Har du ikke noe, så står du fritt til å be en AI om å generere en enkel web-applikasjon i et språk du ønsker (f.eks. Go, Python, Node.js, Java, Rust, C#). Du kan også bruke demo-applikasjonen i dette repoet som utgangspunkt.

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

## Kom i gang lokalt

Først utforsker du demoen: klon den, kjør den lokalt og se at manifestet er gyldig. Deretter [oppretter du ditt eget repo](#opprett-ditt-eget-repo-i-kartverket) og bygger det samme der.

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

Med Docker bygger og kjører du applikasjonen på akkurat samme måte uansett hvilket språk eller rammeverk som ligger i `app/`. Kjør den med samme sikkerhetskontekst som Skiperator bruker på SKIP (UID/GID `150`, ingen capabilities, skrivebeskyttet rot-filsystem der kun `/tmp` er skrivbart), slik at du oppdager problemer før du deployer:

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

# Formater Jsonnet-filen (endrer filen "in place", sjekk med git diff):
skipctl manifest format --path manifestdemo/app.jsonnet
```

Se hvordan resultatet av `render` henger sammen med `manifestdemo/app.jsonnet`: appnavn, image, ingress, replikaer, ressurser og helsesjekker i Jsonnet blir til `spec` i Skiperator-`Application`.

---

## Opprett ditt eget repo i kartverket

Nå som du har sett at demoen virker, lager du ditt eget repo i [`kartverket`](https://github.com/kartverket)-organisasjonen. Bruk reglene fra [Mål for workshopen](#mål-for-workshopen).

**1. Opprett repoet** i nettleseren (*+ → New repository*, Owner `kartverket`, Internal, ingen lisens), eller med GitHub CLI:

```bash
gh repo create kartverket/<mitt-app-navn> --internal --clone
cd <mitt-app-navn>
```

Brukte du nettleseren, klon repoet (se [autentisering](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/github/autentisering-til-github-i-terminalen)) og gå inn i mappen.

**2. Kopier malen inn i repoet.** Fra mappen til ditt nye repo, med demoen klonet ved siden av (`../skip-demo`):

```bash
cp -r ../skip-demo/app ../skip-demo/Dockerfile ../skip-demo/.dockerignore \
      ../skip-demo/.github ../skip-demo/manifestdemo .
```

Kopier *ikke* `.git` eller `argokit/` fra demoen. `argokit` legger du til som submodule i neste steg. På Windows gjør du dette i WSL, eller med `Copy-Item -Recurse` i PowerShell.

**3. Legg til `argokit` som submodule** ([installasjonsguide](https://skip.kartverket.no/docs/applikasjon-utrulling/argokit/installation-guide)):

```bash
git submodule add https://github.com/kartverket/argokit.git
```

**4. Tilpass navn.** Bytt ut `skip-demo` med ditt appnavn i `manifestdemo/app.jsonnet` (appnavn, image og hostnavn) og sett ditt eget team i `.github/CODEOWNERS`. Finn alle steder med:

```bash
grep -rn "skip-demo" . --exclude-dir=.git --exclude-dir=argokit --exclude=README.md
```

**5. Valider og kjør lokalt** med kommandoene fra [Kom i gang lokalt](#kom-i-gang-lokalt) (`docker build`, `docker run`, `skipctl manifest validate`).

**6. Commit og push via en branch og Pull Request.** Repoer i organisasjonen krever signerte commits (se [`Jukselappen.md`](Jukselappen.md)):

```bash
git switch -c oppsett
git add .
git commit -m "Sett opp app, Dockerfile, CI og manifest"
git push -u origin oppsett
```

Åpne en Pull Request og se at workflowene kjører under **Actions**. Merg til `main`, og sjekk at imaget dukker opp under **Packages** på repoet. Pharos-jobben krever at *code scanning* er tilgjengelig for repoet, og `deploy`-jobben hoppes over til du har satt variablene beskrevet under [Apps-repoet](#apps-repoet-slik-deployes-det-til-skip).

**7. Rull ut på SKIP** ved å følge [Apps-repoet](#apps-repoet-slik-deployes-det-til-skip), og gå gjennom [sjekklisten](#sjekkliste-dette-skal-du-ha-laget).

---

## Lag din egen app og pakk den i en container!

Dette repoet er bygget opp som en generell mal du kan kopiere eller ta utgangspunkt i når du vil lage din egen applikasjon og rulle den ut på SKIP. SKIP krever ikke et bestemt programmeringsspråk eller rammeverk, da kontrakten mellom applikasjonen din og plattformen er selve **containeren**.

### Repo-strukturen

Ved å følge strukturen i dette repoet får du et ryddig skille mellom **applikasjonskode**, **container-pakking**, **CI-bygging** og **SKIP-manifest**:

```text
mitt-app-repo/
├── app/                          # Kildekode, avhengigheter, ressurser og tester for din applikasjon
├── Dockerfile                    # Oppskrift for å bygge og pakke app/ inn i et container-image
├── .dockerignore                 # Holder Docker build-konteksten liten
├── .github/
│   ├── CODEOWNERS                # Hvilket team som eier repoet
│   ├── dependabot.yml            # Automatiske oppdateringer (argokit, actions, Docker, Go)
│   ├── pull_request_template.md  # Sjekkliste i Pull Requests
│   └── workflows/
│       ├── workflow.yaml             # Tester, bygger Dockerfile, pusher image til ghcr.io, skanner med Pharos og deployer til apps-repo
│       ├── validate-manifest.yaml    # Validerer manifestet med skipctl på Pull Requests
│       └── dependency-review.yaml    # Sårbarhets- og lisenskontroll av avhengigheter på Pull Requests
├── manifestdemo/
│   └── app.jsonnet               # ArgoKit-manifest som forteller Skiperator hvordan containeren skal kjøres
├── apps-repo-eksempel/           # Slik ser det tilhørende apps-repoet ut (mappestruktur, config.json, Octo STS-tillit)
└── argokit/                      # Git-submodule med ArgoKit-biblioteket for lokal validering med skipctl
```

> **Tips:** GitHub Actions-workflowen i [`.github/workflows/workflow.yaml`](./.github/workflows/workflow.yaml) bruker `${{ github.repository }}` automatisk. Det betyr at hvis du oppretter et nytt repo med denne strukturen, vil workflowen automatisk bygge `Dockerfile` i rotmappen og publisere imaget til `ghcr.io/kartverket/<ditt-repo-navn>` uten at du trenger å endre workflow-filen!

### Steg 1: Legg inn din egen applikasjon i `app/`

Erstatt innholdet i [`app/`](./app) med din egen applikasjon, skrevet i det språket og rammeverket som passer oppgaven best. For at applikasjonen skal fungere godt i en container på SKIP, bør den oppfylle tre grunnleggende ting:

1. **Lytt på en uprivilegert port (f.eks. `8080`):** Bind deg helst til en port over `1024` (f.eks. `0.0.0.0:8080`), siden containeren ikke kjører som `root`. Skiperator gir kun `NET_BIND_SERVICE` til containere som deklarerer en port under `1024`, og dropper alle andre Linux-capabilities.
2. **Eksponer helsesjekk-endepunkter (`/healthz` og `/readyz`):** Lag endepunkter som returnerer HTTP `200 OK` når applikasjonen lever (*liveness*) og når den er klar til å ta imot trafikk (*readiness*).
3. **Konfigurasjon via miljøvariabler:** Les inn innstillinger og eventuelle hemmeligheter fra miljøvariabler, slik at samme container-image kan brukes på tvers av miljøer (lokalt, dev, test og prod).

### Steg 2: Pakk applikasjonen i en container (`Dockerfile`)

[`Dockerfile`](./Dockerfile) i rotmappen definerer hvordan koden i `app/` bygges og pakkes til et kjørbart container-image. Når du tilpasser `Dockerfile` til din applikasjon, bør du følge disse prinsippene for å oppfylle [kravene til Skiperator](https://skip.kartverket.no/docs/applikasjon-utrulling/skiperator/requirements) (containerisert, anbefalt `scratch`-baseimage, publisert til GHCR) og [retningslinjene for Kubernetes](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/kubernetes/retningslinjer-for-kubernetes) (alle workloads følger Pod Security Standards *restricted*):

1. **Bruk Multi-Stage Builds:**
   Del `Dockerfile` inn i et bygg-steg (`FROM <bygg-image> AS builder`) hvor kompilering, transpiling og nedlasting av avhengigheter skjer, og et eget kjøretids-steg til slutt som kun kopierer inn det ferdige resultatet (`COPY --from=builder ...`). Da blir container-imaget lite, raskt å rulle ut og inneholder færrest mulig sårbarheter.
2. **Velg et minimalt kjøretids-image:**
   Bruk et så slankt base-image som mulig i siste steg, for eksempel `scratch`, [Distroless](https://github.com/GoogleContainerTools/distroless) eller offisielle `-slim`/`-alpine`-varianter som kun inneholder selve kjøretidsmiljøet applikasjonen din trenger.
3. **Kjør som ikke-root bruker (`USER 150:150`):**
   Skiperator setter `runAsUser: 150`, `runAsGroup: 150`, `runAsNonRoot: true`, `fsGroup: 150`, `allowPrivilegeEscalation: false`, dropper alle capabilities og bruker seccomp-profilen `RuntimeDefault` på alle containere (se [`pkg/util/constants.go`](https://github.com/kartverket/skiperator/blob/main/pkg/util/constants.go) i Skiperator). Plattformen tvinger altså UID/GID 150 uansett hva imaget sier, men legg likevel inn `USER 150:150` før `ENTRYPOINT`/`CMD` i siste steg av `Dockerfile`, slik at containeren oppfører seg likt lokalt som på SKIP.
4. **Håndter skrivebeskyttet filsystem (`read-only root filesystem`):**
   Skiperator setter `readOnlyRootFilesystem: true` og monterer et `emptyDir`-volum på `/tmp` i alle containere. Applikasjonen kan derfor skrive midlertidige filer til `/tmp`, men ikke andre steder (f.eks. arbeidsmappen). Trenger du flere skrivbare mapper, kan du montere `emptyDir`-volumer med `filesFrom` i `Application`-manifestet. Test lokalt med `docker run --read-only --tmpfs /tmp --user 150:150 ...` (se [`Jukselappen.md`](Jukselappen.md)).
5. **Eksponer riktig port og startkommando:**
   Dokumenter porten med `EXPOSE 8080` og definer hvordan applikasjonen startes med `ENTRYPOINT` eller `CMD`.

### Steg 3: Tilpass manifestet (`manifestdemo/app.jsonnet`)

Oppdater applikasjonsnavn, image-referanse (`ghcr.io/kartverket/<ditt-repo>:...`), port og hostnavn i [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet), og valider lokalt med `skipctl manifest validate --path manifestdemo/app.jsonnet`.

> **Om hostnavn:** `skip-demo.atkv3-dev.kartverket-intern.cloud` i manifestet er kun en plassholder; bytt ut appnavn og cluster. På SKIP følger hostnavn mønsteret `<app>.<cluster>.kartverket-intern.cloud` (kun tilgjengelig internt, f.eks. `skip-demo.atkv3-dev.kartverket-intern.cloud`) eller `<app>.<cluster>.kartverket.cloud` (**åpnes mot internett**, se [Sjekkliste før internetteksponering](https://skip.kartverket.no/docs/applikasjon-utrulling/sjekkliste-f%C3%B8r-internett-eksponering)). Se [URLer og sertifikat for tjenester på SKIP](https://skip.kartverket.no/docs/kom-i-gang/praktisk-intro/kubernetes/urler-og-sertifikat-for-tjenester-p%C3%A5-skip). Tilgjengelige clustere er `atkv3-dev`, `atkv3-prod`, `atgcp1-dev` og `atgcp1-prod`.
>
> **Om ressurser:** Retningslinjene krever at `requests` og `limits` settes for CPU/minne på alle containere. Manifestet i demoen setter dette med `application.resources.withRequests(...)` og `application.resources.withLimits(...)`. Verdiene (`50m` CPU / `64Mi` minne som request og `128Mi` minne som limit) er kun et utgangspunkt: følg med på faktisk forbruk i Grafana og juster. Tommelfingerregel fra SKIP: minne-limit ca. dobbelt så høy som gjennomsnittlig bruk, og ingen CPU-limit.

---

## Fremgangsmåte: Fra kode til kjørende app på SKIP

1. **Utvikler/Applikasjonsdrifter:** Gjør en endring i applikasjonskoden i `app/`, eller endrer konfigurasjon som hostnavn, replikaer, CPU/minne e.l. i apps-repoet.
2. **Git Push / Pull Request:** Endringen merges til `main`-branchen.
3. **GitHub Actions (CI):**
   * Push til `main` trigger automatisk workflowen definert i `.github/workflows/workflow.yaml`.
   * Workflowen bygger et nytt container-image basert på `Dockerfile`.
   * Imaget tagges med commit-SHA og `latest`, og pushes til `ghcr.io/kartverket/<repo-navn>`.
   * Pharos skanner imaget for sårbarheter, og `deploy`-jobben oppdaterer image-taggen i apps-repoet (se [Apps-repoet](#apps-repoet-slik-deployes-det-til-skip)).
4. **ArgoKit og `skipctl`:**
   * ArgoKit v2 Jsonnet-malen (`manifestdemo/app.jsonnet`) brukes for å definere `Application`-manifestet.
   * `skipctl manifest validate` brukes for å verifisere at manifestet er gyldig.
5. **Apps-repo:**
   * Teamets [apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo) oppdateres med det validerte applikasjonsmanifestet. Apps-repoet har en fast mappestruktur (`env/<cluster>/<namespace>/app.yaml`), og SKIP anbefaler å starte med vanlige YAML-filer (render Jsonnet-en med `skipctl manifest render`) mens du lærer systemet. Image-oppdateringen automatiseres av `deploy`-jobben i `workflow.yaml`, se [Deploye automatisk ved push](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo#deploye-automatisk-ved-push).
6. **Synkronisering og utrulling:**
   * **Argo CD** oppdager endringen i apps-repoet og synkroniserer `Application`-manifestet til Kubernetes-clusteret (automatisk eller ved manuell "Sync" i Argo CD).
   * **Skiperator** oppdager endringen i `Application`-ressursen og genererer/oppdaterer de underliggende Kubernetes-ressursene (Deployment, Service, Gateway API-ruting, NetworkPolicy osv.).
   * Sertifikat opprettes automatisk og applikasjonen er tilgjengelig på sitt konfigurerte domene.

---

## Apps-repoet: slik deployes det til SKIP

Applikasjonsmanifestet hører hjemme i teamets **apps-repo**, ikke i kildekode-repoet ([hva er et apps-repo?](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo)). Her ligger `manifestdemo/` kun for at demoen skal være selvforklarende. Mappen [`apps-repo-eksempel/`](./apps-repo-eksempel) viser hvordan det tilhørende apps-repoet ser ut:

```text
apps-repo-eksempel/
├── .github/chainguard/
│   └── skip-demo.sts.yaml            # Octo STS-tillit: lar CI i skip-demo skrive til apps-repoet
└── env/
    └── atkv3-dev/                    # Cluster: atkv3-dev, atkv3-prod, atgcp1-dev eller atgcp1-prod
        └── skip-demo-main/           # Namespace. Må starte med teamets prefiks (f.eks. appnavnet)
            ├── app.yaml              # Skiperator Application (rendret fra manifestdemo/app.jsonnet)
            └── config.json           # Valgfritt: tool, autoSync, prune, selfHeal
```

* **Namespace** opprettes automatisk av Argo CD når mappen dukker opp. Prefikset avtales med SKIP når apps-repoet settes opp ([Komme i gang med Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/komme-i-gang-med-argocd)).
* **`config.json`** styrer synkroniseringen ([dokumentasjon](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/configuring-apps-repositories-with-configjson)). Auto-sync er på som standard i dev, men av i prod.
* **Plain YAML eller Jsonnet?** SKIP anbefaler vanlig YAML mens du lærer systemet. Argo CD støtter også Jsonnet. `app.yaml` i eksempelet er det samme manifestet som `skipctl manifest render` gir fra `manifestdemo/app.jsonnet`.

### Automatisk deploy fra CI (`deploy`-jobben)

Etter bygg og push endrer `deploy`-jobben i [`workflow.yaml`](./.github/workflows/workflow.yaml) `spec.image` i apps-repoet til `ghcr.io/<repo>:sha-<commit>`, committer og pusher. Argo CD ser endringen og synkroniserer, og Skiperator oppdaterer Deployment. Autentiseringen bruker [Octo STS](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/tilgang-til-repoer-med-tokens-fra-github-actions) i stedet for langlevde PAT-er. Slik tar du den i bruk:

1. Legg `.github/chainguard/<repo-navn>.sts.yaml` i **apps-repoet** (se [eksempelet](./apps-repo-eksempel/.github/chainguard/skip-demo.sts.yaml)) og fyll inn org- og repo-ID.
2. Sett repository-variablene `APPS_REPO` (f.eks. `kartverket/skip-demo-apps`) og `APPS_MANIFEST_PATH` (f.eks. `env/atkv3-dev/skip-demo-main/app.yaml`) under *Settings → Secrets and variables → Actions → Variables*.
3. Push til `main`. Uten variablene hoppes jobben over.

> **Rollback:** Argo CD har innebygd rollback (*History and rollback*), men imaget må fortsatt finnes i GHCR. Se [Hvordan bruke Argo CD](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hvordan-bruke-argocd). Feilsøking: [Troubleshooting på SKIP](https://skip.kartverket.no/docs/kom-i-gang/troubleshoot/troubleshooting-on-skip).

---

## Sjekkliste: dette skal du ha laget

Workshop-oppgaven er å sette opp det samme for din egen app. Når du er ferdig skal følgende stemme:

- [ ] Du har opprettet et eget repo i GitHub-organisasjonen `kartverket` (Internal, uten lisens), med `CODEOWNERS` og tilgang for teamet ditt.

- [ ] `app/` svarer 200 på `/healthz` og `/readyz`, lytter på `PORT` (standard `8080`) og stopper pent på SIGTERM.
- [ ] `docker build` fungerer, og containeren kjører med `--read-only --tmpfs /tmp --user 150:150 --cap-drop ALL`.
- [ ] `Dockerfile` er multi-stage, ender i `scratch` (eller tilsvarende), har `USER 150:150` og `EXPOSE`.
- [ ] CI kjører tester, bygger og pusher til `ghcr.io/kartverket/<repo>` ved push til `main`.
- [ ] `skipctl manifest validate` er grønn for manifestet, og `resources`, probes, `routingProvider: Standard` og ingress er satt.
- [ ] Manifestet ligger i apps-repoet under `env/<cluster>/<namespace>/`, og Argo CD viser appen som *Synced* og *Healthy*.
- [ ] Appen svarer på ingress-hostnavnet over HTTPS.

---

## Ekstraoppgave: Bygg ut GitHub Actions-oppsettet

*For deg som er ferdig med resten tidlig.* Repoet har allerede en solid grunnkonfigurasjon i `.github/`. Les gjennom den først, den er ment som en mal du kan ta med deg til egne repoer. Se også [GitHub Actions på SKIP](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions).

| Fil | Hva den gjør | Dokumentasjon |
| :--- | :--- | :--- |
| [`workflow.yaml`](./.github/workflows/workflow.yaml) | `test`-jobb (`go vet`, `go test`), `build`-jobb (bygger og pusher til GHCR), `pharos`-jobb (skanner imaget etter push til `main`) og `deploy`-jobb (se under) | [Pharos](https://skip.kartverket.no/docs/applikasjon-utrulling/github-actions/pharos) |
| (`deploy`-jobben i `workflow.yaml`) | Oppdaterer image-taggen i apps-repoet via Octo STS | [Apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo#deploye-automatisk-ved-push) |
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

### Oppgave B: Semver-tagger ved release

I dag får imaget kun taggene `sha-<commit>` og `latest`. Legg til støtte for versjonerte releaser.

* [ ] Trigg `workflow.yaml` også på `push` av tags som matcher `v*.*.*`.
* [ ] Legg til `type=semver,pattern={{version}}` i `docker/metadata-action` og sørg for at `latest` fortsatt kun settes på `main`.
* [ ] Lag en tag (`git tag v0.1.0 && git push --tags`) og sjekk at riktige tagger dukker opp under **Packages**.
* [ ] Tenk gjennom: hva bør `pharos`-jobben (som i dag kun kjører på `main`) gjøre ved tag-bygg?

### Oppgave C (utfordring): Eget namespace per branch, med opprydding

Apps-repoet støtter ett namespace per branch eller PR (`<prefiks>-<branch>`), noe som lar deg teste endringer isolert før merge. Utvid `deploy`-jobben slik at den også kjører for andre branches enn `main`, og kopierer manifestet til `env/<cluster>/<prefiks>-<branch>/`. Lag deretter en `on: delete`-workflow som fjerner mappen igjen når branchen slettes, slik at du ikke bruker opp clusterkapasitet. Se eksemplene nederst i [Hva er et apps-repo](https://skip.kartverket.no/docs/applikasjon-utrulling/argo-cd/hva-er-et-apps-repo#deploye-automatisk-ved-push). Obs: eksemplet i dokumentasjonen bruker `kubectl patch --local ... -o yaml`, som kun skriver til stdout og ikke endrer filen. Bruk `yq -i` eller omdiriger output. Hostnavnet i manifestet må også være unikt per branch.

### Oppgave D: Gjør `skipctl` tilgjengelig som eget steg

`validate-manifest.yaml` laster ned `skipctl` med en fast versjon. Utvid den slik at den også:

* [ ] Kjører `skipctl manifest render --path manifestdemo/app.jsonnet` og laster opp resultatet som artifact (`actions/upload-artifact`), slik at reviewere kan se det ferdige YAML-manifestet.
* [ ] Sjekker at Jsonnet-filen er formatert (`skipctl manifest format` etterfulgt av `git diff --exit-code`).

---

## Nøkkelfiler i dette repoet

* [`app/`](./app): Kildekoden til applikasjonen som skal kjøres på SKIP.
* [`Dockerfile`](./Dockerfile): Multi-stage oppskrift for å bygge applikasjonen i `app/` og pakke den til et minimalt, sikkert container-image.
* [`.github/workflows/`](./.github/workflows): GitHub Actions-workflows for test, bygg og push til GHCR ([`workflow.yaml`](./.github/workflows/workflow.yaml)), Pharos-skanning, manifestvalidering og dependency review.
* [`apps-repo-eksempel/`](./apps-repo-eksempel): Eksempel på hvordan det tilhørende apps-repoet er strukturert (`env/<cluster>/<namespace>/`, `config.json` og Octo STS-tillit).
* [`.github/dependabot.yml`](./.github/dependabot.yml): Automatiske oppdateringer av `argokit`, GitHub Actions, Docker-imaget og Go-avhengigheter.
* [`.github/CODEOWNERS`](./.github/CODEOWNERS): Hvilket team som eier repoet. Bytt ut teamet når du bruker repoet som mal.
* [`manifestdemo/app.jsonnet`](./manifestdemo/app.jsonnet): Eksempel på en Skiperator `Application`-ressurs skrevet med **ArgoKit v2**. *Merk: I en reell utrulling skal denne filen ligge i teamets apps-repo slik at den plukkes opp av Argo CD.*
* [`argokit/`](./argokit): [ArgoKit](https://github.com/kartverket/argokit)-repoet lagt til som en Git-submodule for tilgang til Jsonnet-bibliotekene i `argokit/v2`.
* [`Jukselappen.md`](Jukselappen.md): Oppslagsverk og jukselapp med grunnleggende kommandoer for terminal, Git, Docker, Podman og `skipctl`.
