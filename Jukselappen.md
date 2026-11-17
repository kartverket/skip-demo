# Jukselapp: Grunnleggende kommandoer

Denne oversikten er laget som en rask oppslagsguide for deg som ønsker litt ekstra støtte med **terminalen**, **Git**, **Docker/Podman** og **`skipctl`** når du jobber med denne demoen.

---

## 1. Terminal og kommandolinje

Uavhengig om du bruker **Terminal** (macOS/Linux), **WSL** (Windows) eller **PowerShell** (Windows), er disse grunnleggende kommandoene nyttige for å navigere i prosjektet:

| Kommando | Beskrivelse |
| :--- | :--- |
| `pwd` | Viser hvilken mappe (arbeidskatalog) du befinner deg i akkurat nå |
| `ls` | Lister ut filer og mapper der du står (`ls -la` viser også skjulte filer som `.github` og `.gitignore`) |
| `cd <mappenavn>` | Går inn i en mappe (f.eks. `cd skip-demo` eller `cd app`) |
| `cd ..` | Går ett mappenivå opp (tilbake) |
| `curl http://localhost:8080/healthz` | Tester et HTTP-endepunkt direkte fra terminalen (`curl -i ...` viser også HTTP-statuskode som `200 OK`) |
| `Ctrl + C` | Tastatursnarvei for å avbryte/stoppe et program eller en container som kjører i terminalvinduet |

---

## 2. Git (Versjonskontroll)

Git brukes til å hente ned kode, lagre endringer underveis og laste dem opp til GitHub slik at GitHub Actions og Argo CD kan bygge og rulle ut applikasjonen.

### Førstegangsoppsett (hvis du aldri har brukt Git på maskinen før)
```bash
git config --global user.name "Ditt Navn"
git config --global user.email "din.epost@kartverket.no"
```

### Klone repoet og hente undermoduler (`submodules`)
Dette repoet bruker [ArgoKit](https://github.com/kartverket/argokit) som en Git-submodule. Derfor må undermodulen også lastes ned:
```bash
# Klone repoet og laste ned submodules i én kommando:
git clone --recurse-submodules https://github.com/kartverket/skip-demo.git
cd skip-demo

# Hvis du allerede har klonet repoet uten --recurse-submodules:
git submodule update --init --recursive
```

### Daglig arbeidsflyt i Git
```bash
# 1. Sjekk hvilke filer som er endret og hvilken branch du står på:
git status

# 2. Se nøyaktig hvilke linjer du har endret i filene:
git diff

# 3. Hent siste endringer fra GitHub til din lokale maskin:
git pull

# 4. Opprett og bytt til en ny branch (gren) for endringen din:
git switch -c min-nye-endring

# 5. Klargjør (stage) alle endrede filer for lagring:
git add .

# 6. Lagre (commit) endringene lokalt med en beskrivende melding:
git commit -m "Oppdater tekst på forsiden"

# 7. Last opp (push) branchen din til GitHub:
git push -u origin min-nye-endring
```

> **Tips:** Etter at du har kjørt `git push`, kan du gå til repoet på GitHub i nettleseren for å opprette en **Pull Request** og flette (merge) endringen inn i `main`.

---

## 3. Docker og Podman (Containere)

En **container** pakker applikasjonen din sammen med alt den trenger for å kjøre.
* Bruker du **macOS** eller **Linux**, bruker du som regel kommandoen `docker`.
* Bruker du **Windows** (med Podman Desktop), bruker du kommandoen `podman`.

> **Visste du?** `podman` og `docker` har helt like kommandoer! Hvis du bruker Podman, bytter du bare ut ordet `docker` med `podman` i alle eksemplene under (f.eks. `podman build ...` og `podman run ...`).

### Kun for Podman (Windows / macOS)
På Windows og macOS kjører Podman containere inne i en lettvekts virtuell maskin. Hvis du får feilmelding om at Podman ikke får kontakt med motoren sin, sjekk at maskinen kjører:
```bash
# Se status på Podman-maskinen:
podman machine list

# Opprett maskinen (trengs kun første gang):
podman machine init

# Start eller stopp Podman-maskinen:
podman machine start
podman machine stop
```

### Bygge og kjøre applikasjonen
```bash
# Bygg et container-image fra Dockerfile i nåværende mappe (punktumet til slutt betyr "denne mappen"):
# -t gir imaget et navn og en tag ("skip-demo:local")
docker build -t skip-demo:local .

# Kjør containeren i forgrunnen:
# --rm sletter containeren automatisk når den stoppes
# -p 8080:8080 kobler port 8080 på din maskin til port 8080 inne i containeren
docker run --rm -p 8080:8080 skip-demo:local

# Kjør containeren med en miljøvariabel (-e):
docker run --rm -p 8080:8080 -e PORT=8080 skip-demo:local

# Kjør containeren i bakgrunnen (-d) med et eget navn (--name):
docker run -d --rm --name min-demo-app -p 8080:8080 skip-demo:local
```

### Inspisere og stoppe containere
```bash
# Se alle containere som kjører akkurat nå:
docker ps

# Se loggene fra en container som kjører i bakgrunnen (-f følger loggen fortløpende):
docker logs -f min-demo-app

# Stopp en container som kjører i bakgrunnen:
docker stop min-demo-app

# Se alle container-images du har bygget eller lastet ned lokalt:
docker images

# Rydd opp i ubrukte images og containere for å frigjøre diskplass:
docker system prune
```

---

## 4. `skipctl` (Validering av SKIP-manifester)

`skipctl` er Kartverkets eget kommandolinjeverktøy for å jobbe med Skiperator- og ArgoKit-manifester lokalt før du dytter dem til GitHub.

```bash
# Sjekk at skipctl er installert og hvilken versjon du har:
skipctl -v

# Se hjelpetekst og tilgjengelige kommandoer:
skipctl --help
skipctl manifest --help

# 1. Rendre: Se hvordan Jsonnet-filen oversettes til ferdig Kubernetes-YAML:
skipctl manifest render --path manifestdemo/app.jsonnet

# 2. Validere: Sjekk at manifestet er gyldig mot Kubernetes- og Skiperator-skjemaer:
skipctl manifest validate --path manifestdemo/app.jsonnet

# 3. Formatere: Rydd opp i innrykk og formatering i Jsonnet-filen:
skipctl manifest format --path manifestdemo/app.jsonnet
```

---

## 5. Vanlige feilmeldinger og løsninger

* **`port is already allocated` / `address already in use` når du kjører `docker run`:**
  Port `8080` er allerede i bruk på maskinen din (ofte fordi en annen container allerede kjører).
  * *Løsning:* Kjør `docker ps` (eller `podman ps`) for å se om containeren allerede kjører, eller bytt lokal port ved å kjøre `docker run --rm -p 8081:8080 skip-demo:local` og åpne `http://localhost:8081`.
* **`RUNTIME ERROR: couldn't open import "argokit/..."` når du kjører `skipctl`:**
  Mappen `argokit/` er tom fordi Git-submodulen ikke er lastet ned ennå.
  * *Løsning:* Kjør `git submodule update --init --recursive` i rotmappen av repoet.
* **`permission denied` inne i containeren ved oppstart:**
  Containere på SKIP kjører som en uprivilegert bruker (`USER 150:150`) og med skrivebeskyttet filsystem.
  * *Løsning:* Sørg for at applikasjonen lytter på en port over `1024` (f.eks. `8080`), og at den ikke forsøker å skrive filer direkte til disk ved oppstart.
