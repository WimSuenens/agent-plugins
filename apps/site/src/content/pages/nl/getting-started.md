Vier stappen brengen je van niets naar een eerste commando. Je hebt Claude Code nodig. De fabriek heeft ook een GitHub-repository en het opdrachtregelprogramma `gh` nodig.

## Voeg de marketplace toe

In een Claude Code-sessie:

```
/plugin marketplace add WimSuenens/agent-plugins
```

Of vanuit een terminal: `claude plugin marketplace add WimSuenens/agent-plugins`.

## Installeer de plugins die je wilt

De marketplace heet `wimsuenens`. Elke plugin installeer je apart.

```
claude plugin install mattpocock-skills@wimsuenens
claude plugin install wayfinding@wimsuenens
claude plugin install factory@wimsuenens
```

De fabriek bouwt voort op wayfinding en op `mattpocock-skills`, dus installeer die twee erbij. De andere plugins zijn optioneel; de [Reference](/reference/) (in het Engels) toont elke vaardigheid van elke plugin.

Als de installatie `Run /reload-plugins to activate.` meldt, voer dat dan uit en start daarna een nieuwe sessie. Een sessie houdt de tekst van de vaardigheden vast die hij bij het starten las, dus een oude sessie draait de oude tekst.

Als de installatie vanaf de bron met een SSH-fout mislukt: GitHub-verkortingen als bron worden standaard via SSH gekloond. Zet `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` vóór het installatiecommando om HTTPS te gebruiken.

## Richt je repository in, eenmalig

```
/wayfinding:setup-wayfinding-skill
/factory:setup-factory-skill
```

Het eerste commando zet de planningsafspraken in het document van je issuetracker. Het tweede schrijft `docs/agents/factory.md` en maakt het GitHub-projectbord klaar. Voorlopig wordt voor de fabriek alleen GitHub als tracker ondersteund.

## Voer je eerste commando uit

Begin bij de kaart als je iets groots wilt plannen:

```
/wayfinding:wayfinder
```

Laat de fabriek een idee helemaal uitwerken tot samengevoegde pull requests met:

```
/factory:run "your idea in a sentence"
```

De fabriek stelt een paar vragen over de bestemming en gaat dan aan het werk. Ze komt alleen bij je terug voor de beslissingen die niet terug te draaien zijn.
