---
name: eyra-test-scan
description: |
  Test gap-analyse voor een nieuwe feature, milestone of branch in het Eyra Next platform (mono repo).
  Scant gewijzigde productiecode en checkt of er voldoende unit tests (ExUnit), feature tests (Wallaby)
  en E2E tests (Playwright) zijn. Output is concreet advies voor developers,
  plus de vraag of er nog een E2E spec ontbreekt.
triggers:
  - test-scan
  - /test-scan
  - test gap
  - test gap analysis
  - testdekking
  - test coverage check
---

# Test Scan — gap-analyse voor Eyra Next

Deze skill helpt bij het beoordelen van een nieuwe feature of milestone:

1. Of de developers genoeg unit/feature tests hebben geschreven (zo niet → advies terug).
2. Of er nog een E2E spec moet komen (zo ja → `/e2e-create`).

## Stap 1 — Scope bepalen

Vraag (als niet gegeven): wat is de scope?

- **Branch** — feature branch die nog open staat. Gebruik `git diff develop..HEAD --stat`
  om gewijzigde files te vinden.
- **PR-nummer / URL** — `gh pr view <id>` om de branch te krijgen, dan diff zoals boven.
- **Vrij** — een feature wordt bij naam genoemd. Vraag dan welke modules dat raakt of zoek met
  `grep -r` naar relevante symbolen.

## Stap 2 — Conventies inlezen

Voor je gaat oordelen, **lees eerst** de actuele test-conventies in mono. Doe een find — paden
kunnen verschuiven:

```bash
find core/test -maxdepth 4 -name CLAUDE.md
find core/test -maxdepth 4 -name AGENTS.md
```

Verwacht (op moment van schrijven): `core/test/.claude/CLAUDE.md` (de 5 regels: atomic, guards
eerst, let-it-crash, standaard tuples, pattern match in function heads), `core/test/CLAUDE.md`
(Wallaby selectors, signal isolation), `core/test/e2e/CLAUDE.md` (Playwright conventies). Lees ze
allemaal voor je adviezen formuleert.

## Stap 3 — Productiecode lijsten

```bash
git diff develop..HEAD --stat -- 'core/lib/**' 'core/systems/**' 'core/frameworks/**'
git diff develop..HEAD --stat -- 'core/test/**'
```

Maak twee lijsten:
- **Nieuwe of zwaar gewijzigde productie-modules** (ratio additions/deletions hoog).
- **Tegelijk gewijzigde test files**.

## Stap 4 — Per module checken

Voor elke productie-module:

1. Bestaat er een `*_test.exs` op het gespiegelde pad in `core/test/`?
   - Bv. `core/systems/foo/bar.ex` → `core/test/systems/foo/bar_test.exs`
2. Tel atomic tests:
   ```bash
   grep -c "^    test " core/test/systems/foo/bar_test.exs
   ```
3. **LiveComponent of LiveView?** (grep op `use Phoenix.LiveComponent` / `use Phoenix.LiveView`)
   - Check of de test `live_isolated` gebruikt. Zo niet → vlag dit specifiek; LiveComponent state
     hoort op unit-niveau getest, niet uitgesteld naar feature/E2E.
4. **Public functions zonder guards?** Vlag het, want regel 3 zegt: guards eerst, met tests.
5. **Coverage cijfer** voor de touched paths:
   ```bash
   cd core && mix test --cover test/systems/foo
   ```
   (Alleen draaien als de branch lokaal uitgechecked is en de DB klaar staat — `mix ecto.migrate`
   in `core/` bij twijfel.)

## Testverdeling — streefverhouding

De afgesproken verdeling voor deze codebase:

| Laag | Tool | Stijl | Aandeel |
|---|---|---|---|
| Unit | ExUnit (Phoenix) | **Whitebox** — interne logica, edge cases, regression-safety | 90% |
| Feature | Wallaby (headless browser, mini-E2E) | **Greybox** — UI flows, multi-user of JS-hooks | 9% |
| E2E | Playwright | **Blackbox** — happy path zoals de gebruiker die doorloopt, één flow per kritiek systeem | 1% |

Gebruik dit als ijkpunt bij het beoordelen van een PR. Als een PR relatief veel feature- of E2E-tests toevoegt ten opzichte van unit tests, is dat een vlag.

## Stap 5 — Feature-tests beoordelen

Default voor UI-werk is **unit** via `live_isolated`, niet feature. Feature is alleen nodig als:

- Echt twee gebruikers tegelijk meedoen (`@sessions 2` in Wallaby), of
- JavaScript-hooks die je niet in `live_isolated` kunt namaken.

Voor de PR-scope: kijk in `core/test/features/` of er al een relevante flow-test bestaat. Als de PR
zo'n flow toevoegt, vraag jezelf af of het écht niet door unit-laag afgevangen kan worden — vlag
dat in je advies als de keuze niet evident is.

## Stap 6 — E2E checken

E2E test de happy path zoals een gebruiker die doorloopt — één flow per kritiek systeem. Check `core/test/e2e/`:

```bash
ls core/test/e2e/*.spec.ts
```

Als de PR een nieuw kritiek systeem introduceert (= een nieuwe top-level user journey) zonder
bestaande E2E spec → noteer dit als kandidaat voor `/e2e-create`. Als het systeem al een spec
heeft → niets toevoegen, E2E is geen edge-case-laag.

## Stap 7 — Rapport schrijven

Output in dit formaat:

```
## Test Scan — <scope>

### Unit (ExUnit) — advies aan developers
- <module>: <bevinding>
  Voorstel: <concrete actie>

### Feature (Wallaby) — advies aan developers
- <flow>: <bevinding>
  Voorstel: <concrete actie>

### E2E (Playwright)
- [ ] E2E spec ontbreekt voor <systeem> → kandidaat voor /e2e-create
- [x] Bestaande spec dekt het systeem af (<spec.ts>) — niets toevoegen

### Samenvatting
- Productie-regels toegevoegd: <N>
- Test-regels toegevoegd: <M>
- Ratio: <M/N> (rode vlag als < 1:1 bij kerncomponenten)
- Verdeling nieuwe tests: <X>% unit / <Y>% feature / <Z>% E2E (streef: 90/9/1)
```

## Belangrijke do's en don'ts

- **Adviseer niet om feature tests toe te voegen als unit-laag het beter kan** — de testpiramide
  zegt: focus op unit, feature is middenweg, E2E is de happy path. Wees streng.
- **Vlag LiveComponent zonder `live_isolated`-test** als regelmatige gap — dit wordt vaak vergeten.
- **Buggy-gedrag-tests die na een fix breken** zijn normaal — als je die ziet, geen rode vlag, maar wel even melden dat ze actie nodig hebben na de fix.
- **Mix taken botsen niet met `mix phx.server`** zolang ze geen endpoint starten. `mix ecto.migrate`
  en `mix seed` zijn veilig parallel, `mix run priv/repo/seeds.exs` niet (start de hele app).
- **Geen aanbeveling om `mix test --cover` op de hele suite te draaien** — alleen op de touched
  paths. Anders te traag en niet PR-relevant.
- Pad-shifts: als `find core/test -name CLAUDE.md` minder oplevert dan vroeger, kijk of de inhoud
  naar `AGENTS.md` of een andere locatie is verhuisd voor je oordelen baseert op een verouderd
  document.
