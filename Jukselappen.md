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

### Sette opp signerte commits (`Signed Commits`)
I Kartverket krever mange repoer at commits er kryptografisk signert (**Verified** på GitHub) for å bekrefte avsenderen. Den enkleste måten å sette opp dette på (på macOS, Linux og Windows) er å signere med en **SSH-nøkkel**:

#### 1. Finn eller opprett en SSH-nøkkel
```bash
# Sjekk om du allerede har en SSH-nøkkel (se etter f.eks. id_ed25519.pub):
ls ~/.ssh

# Hvis du ikke har en nøkkel fra før, opprett en ny (trykk Enter for standard filplassering):
ssh-keygen -t ed25519 -C "din.epost@kartverket.no"

# Skriv ut den offentlige nøkkelen og kopier hele linjen (starter med "ssh-ed25519 ..."):
cat ~/.ssh/id_ed25519.pub
```

#### 2. Legg til nøkkelen som `Signing Key` på GitHub
1. Gå til [GitHub](https://github.com) → klikk på profilbildet ditt øverst til høyre → **Settings**.
2. Velg **SSH and GPG keys** i venstre meny og klikk på **New SSH key**.
3. Gi nøkkelen en tittel (f.eks. `Signering - Arbeidsmaskin`).
4. **Viktig:** Under **Key type**, velg **`Signing Key`** (ikke *Authentication Key*).
5. Lim inn den offentlige nøkkelen (`id_ed25519.pub`) i **Key**-feltet og klikk **Add SSH key**.

#### 3. Konfigurer Git til å signere commits automatisk
Kjør disse kommandoene i terminalen for å skru på automatisk signering i Git:
```bash
# Fortell Git at SSH skal brukes til signering:
git config --global gpg.format ssh

# Pek Git til den offentlige SSH-nøkkelen din:
git config --global user.signingkey ~/.ssh/id_ed25519.pub

# Skru på automatisk signering for alle commits og tags:
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```
> **Viktig:** E-posten du har satt i `git config --global user.email` må være lagt til og verifisert under **Settings → Emails** på GitHub-kontoen din for at commitene skal få merket **Verified**.

#### 4. Signere commits (og fikse en usignert commit)
Når `commit.gpgsign` er satt til `true`, blir hver vanlige `git commit -m "..."` automatisk signert.
```bash
# Signere en enkelt commit manuelt (-S):
git commit -S -m "Min signerte endring"

# Hvis din siste lokale commit ble laget uten signatur, kan du signere den på nytt slik:
git commit --amend --no-edit -S
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

### Laste opp et image til et GitHub-repo (`ghcr.io`)

Til vanlig bygger og publiserer GitHub Actions container-imaget automatisk når du pusher kode til `main`. Hvis du i stedet ønsker å bygge og laste opp et image direkte fra din egen maskin til GitHub Container Registry (`ghcr.io`), følger du disse stegene fra innlogging til opplasting:

#### 1. Opprett et Personal Access Token (PAT) på GitHub
For å logge inn fra terminalen trenger du et tilgangstoken (ikke ditt vanlige GitHub-passord):
1. Gå til [GitHub](https://github.com) → klikk på profilbildet ditt øverst til høyre → **Settings**.
2. Bla helt ned i venstre meny og klikk på **Developer settings**.
3. Velg **Personal access tokens** → **Tokens (classic)** → **Generate new token** → **Generate new token (classic)**.
4. Gi tokenet en beskrivelse (f.eks. `ghcr-login`), velg utløpstid, og kryss av for **`write:packages`** (dette huker også av `read:packages` automatisk).
5. Klikk **Generate token** nederst og **kopier tokenet** med én gang.
6. **Viktig for `kartverket`-repoer:** Klikk på **Configure SSO** til høyre for det nye tokenet og velg **Authorize** for `kartverket`.

#### 2. Logg inn mot `ghcr.io` i terminalen
Kjør kommandoen under (bytt ut `<ditt-github-brukernavn>` med brukernavnet ditt, med kun små bokstaver). Når terminalen spør etter `Password:`, limer du inn tokenet du nettopp kopierte:

```bash
# Logg inn interaktivt (fungerer i alle terminaler og PowerShell):
docker login ghcr.io -u <ditt-github-brukernavn>

# Alternativt på macOS / Linux / WSL via standard input:
echo "<ditt-token>" | docker login ghcr.io -u <ditt-github-brukernavn> --password-stdin
```
*(Husk å bytte ut `docker` med `podman` dersom du bruker Podman).*

#### 3. Bygg eller navngi (tag) imaget for GitHub-repoet
GitHub kobler container-imaget til riktig repo basert på navneformatet `ghcr.io/<eier-eller-org>/<repo-navn>:<tag>`. **Merk:** Hele adressen må skrives med små bokstaver.

> **Tips for Mac med Apple Silicon (M1/M2/M3/M4):** Serverne på SKIP kjører på `linux/amd64`-arkitektur. Hvis du bygger et image lokalt på en nyere Mac for å kjøre det på SKIP, må du legge på `--platform linux/amd64`.

```bash
# Alternativ A: Bygg imaget direkte med riktig navn og plattform for SKIP:
docker build --platform linux/amd64 -t ghcr.io/kartverket/<repo-navn>:latest .

# Alternativ B: Gi en ny tag til et image du allerede har bygget lokalt (f.eks. skip-demo:local):
docker tag skip-demo:local ghcr.io/kartverket/<repo-navn>:latest
```

#### 4. Last opp (push) imaget til GitHub
Når imaget er bygget og tagget, laster du det opp til GitHub Container Registry:

```bash
docker push ghcr.io/kartverket/<repo-navn>:latest
```

Når opplastingen er ferdig, finner du imaget igjen under **Packages** til høyre på hovedsiden til GitHub-repoet ditt.

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
  Containere på SKIP kjører som en uprivilegert bruker (UID/GID `150`), uten Linux-capabilities og med skrivebeskyttet rot-filsystem. Kun `/tmp` er skrivbart.
  * *Løsning:* Sørg for at applikasjonen lytter på en port over `1024` (f.eks. `8080`), og at den kun skriver filer til `/tmp`. Du kan gjenskape SKIP-miljøet lokalt med:
    ```bash
    docker run --rm --read-only --tmpfs /tmp --user 150:150 --cap-drop ALL \
      --security-opt no-new-privileges -p 8080:8080 skip-demo:local
    ```
* **`denied: permission_denied` eller `unauthorized` når du kjører `docker push ghcr.io/...`:**
  Du mangler gyldig innlogging eller skriverettigheter mot GitHub Container Registry.
  * *Løsning:* Sjekk at du har kjørt `docker login ghcr.io`, at ditt Personal Access Token (classic) har rettigheten `write:packages`, at du har valgt **Configure SSO → Authorize** for `kartverket` på tokenet, og at hele image-adressen kun bruker små bokstaver.
* **`Commits must have verified signatures` når du forsøker å pushe eller merge på GitHub:**
  Repoet krever signerte commits, men commiten din ble laget uten signatur (eller med en nøkkel/e-post som ikke er registrert som `Signing Key` på GitHub).
  * *Løsning:* Følg stegene under [Sette opp signerte commits](#sette-opp-signerte-commits-signed-commits) over, signer den siste commiten på nytt med `git commit --amend --no-edit -S`, og push med `git push --force-with-lease`.
