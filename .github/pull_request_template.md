## Beskrivelse
<!-- Hva endrer denne PR-en, og hvorfor? -->

## Sjekkliste
- [ ] Applikasjonen lytter fortsatt på riktig port og svarer på `/healthz` og `/readyz`
- [ ] Containeren fungerer med SKIP-sikkerhetskonteksten (`--read-only --tmpfs /tmp --user 150:150 --cap-drop ALL`)
- [ ] `skipctl manifest validate --path manifestdemo/app.jsonnet` er grønn (hvis manifestet er endret)
- [ ] README/Jukselappen er oppdatert (hvis relevant)
