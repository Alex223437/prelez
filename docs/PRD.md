# Přelez – PRD

Verze 0.2 · 14. 10. 2026 · semestrální projekt AP9PT

## Cíl
Appka pro lezce, kteří trénují na Vertikonu ve Zlíně. Umí tři věci:
- zapsat pokus bez odemykání mobilu, i s rukama od magnézia;
- ukázat přehled aktuálních cest na stěně a statistiky;
- pomocí AI na zařízení pochopit, jak lezci o cestách mluví („ta žlutá 6c v převisu“).

Appka nenahrazuje Vertical-Life, kde zůstávají žebříčky a závody. Doplňuje to, co VL na iPhonu a Macu neumí:
Siri a Zkratky, Live Activity, rychlý zápis a AI.

## Funkce
- **F1 – Cesty.** Seznam aktivních cest a boulderů Vertikonu ze snapshotu (JSON od stavěčů).
  - U každé cesty: barva chytů, obtížnost, sektor, stavěč, datum postavení.
  - Seskupení podle sektorů, přepínač cesty/bouldery.
- **F2 – Detail cesty.** Údaje o cestě a moje pokusy na ní. Tlačítka „Přelez“ a „Pád“.
  - Styl přelezu se dopočítá: první pokus = flash, jinak RP. Dá se změnit.
- **F3 – Trénink (session).** Zahájení a ukončení tréninku. Každý pokus patří do běžící session.
  - Pokus mimo session session automaticky založí.
  - Přehled session: čas, počet pokusů a přelezů.
- **F4 – Rychlý zápis s AI.** Uživatel napíše nebo nadiktuje třeba „žlutá 6c v převisu RP“.
  - Appka najde cestu i výsledek a nabídne zápis k potvrzení.
  - Nejdřív se použijí pravidla a slovník charakteru cest („se skokem“, „lištovitá“, „oblá“).
  - Foundation Models na zařízení jen překládají volný text v podporovaných jazycích (angličtina od Erasmus lezců)
    do pevného slovníku: barva, sektor, charakter, výsledek. Cestu vždy vyberou pravidla, model ji nikdy nevybírá.
  - Když AI není k dispozici nebo selže, rozhodnou pravidla a uživatel vidí proč.
- **F5 – Statistiky.** Pyramida přelezů podle obtížnosti a počet pokusů a přelezů po týdnech (Swift Charts).
- **F6 – App Intents.** Obojí funguje ze Zkratek, Siri i Action buttonu bez otevření appky.
  - „Zapiš pokus“: cesta + výsledek.
  - „Jaký je můj nejtěžší přelez?“: odpověď dialogem.
- **F7 – Import nového snapshotu po přestavbě.**
  - Nové cesty přibudou.
  - Cesty, které ve snapshotu chybí, se archivují.
  - Historie pokusů zůstane.
- **F8 (fáze 2) – Live Activity tréninku.** Běží v Dynamic Islandu a na zamčené obrazovce, s tlačítky +přelez / +pád.
- **F9 (fáze 2) – „Co projektovat?“** AI doporučí nepřelezené cesty kolem mé maximální obtížnosti.
  - Doporučovat smí jen cesty, které existují a které nemám přelezené.

## Edge cases
- **Žádné cesty (první spuštění):** zobrazí se „Zatím žádné cesty“ a tlačítko „Importovat cesty“.
- **AI není k dispozici** (vypnutá Apple Intelligence, nepodporované zařízení, model se stahuje):
  zobrazí se hláška a ruční výběr cesty. F4 funguje dál.
- **Model na zařízení neumí česky** (`supportsLocale(cs_CZ) == false`): česká poznámka jde jen přes pravidla
  a slovník, AI se nevolá. Viz AGENT-BUGS #1.
- **Popis neodpovídá žádné cestě** („fialová 9a“): zobrazí se „Nenalezeno“.
  Nic se neuloží a appka si cestu nevymyslí.
- **Nejednoznačný popis** („ta žlutá“): nabídne se výběr z kandidátů, ne náhodná cesta.
- **Zápis bez diakritiky** („zluta 6c previs“): funguje stejně.
- **„6b“ a „6B“ jsou různé obtížnosti:** malá písmena = francouzská stupnice na laně, velká = Font u boulderů.
- **Přestavba:** cesta zmizí ze snapshotu a přesune se do archivu. Pokusy na ní zůstanou ve statistikách.

## Mimo rozsah
- Zápis do Vertical-Life / 8a.nu a jakékoli napojení na jejich API (veřejné API neexistuje).
- Backend, účty, sdílení, synchronizace přes iCloud.
- Externí LLM (Claude, OpenAI…). Veškerá AI běží na zařízení, žádná data neodcházejí.
- Samostatná appka pro Apple Watch a analýza videí s betou (v2).

## Akceptační kritéria

| # | Udělám | Musím vidět |
|---|---|---|
| A1 | Na prázdné appce ťuknu „Importovat cesty“ a vyberu snapshot | Seznam cest seskupený podle sektorů. Počet cest sedí se souborem. |
| A2 | Na cestě zapíšu pád a pak přelez → zabiju appku (app switcher, swipe up) → otevřu | Oba pokusy jsou v detailu cesty i v session. |
| A3 | Do rychlého zápisu napíšu „žlutá 6c v převisu RP“ | Návrh: správná cesta + přelez RP. Po potvrzení je pokus v session. |
| A4 | Napíšu „zluta 6c previs“ | Stejná cesta jako v A3. |
| A5 | Napíšu „fialová 9a“ | „Nenalezeno“, nic se neuložilo. |
| A6 | Napíšu „ta žlutá“ (žlutých cest je víc) | Výběr z kandidátů, žádná cesta se nevybrala sama. |
| A7 | Vypnu Apple Intelligence → rychlý zápis | Hláška o nedostupné AI + ruční výběr. Appka nespadne. |
| A8 | Ve Zkratkách spustím „Zapiš pokus“ (cesta, přelez) | Dialog ve Zkratkách, appka se neotevře. Pokus je v appce i po restartu. |
| A9 | Importuji snapshot, ve kterém chybí cesta, na které mám pokusy | Cesta je v archivu, její pokusy zůstaly ve statistikách. |
| A10 | Zapíšu přelezy 3× 6a, 2× 6b, 1× 6c | Pyramida 3-2-1 ve správném pořadí obtížností. |
| A11 | Napíšu „červená 6b“, pak „červená 6B“ | Poprvé cesta na laně, podruhé boulder. |
| A12 | Spustím eval (3 běhy golden setu) | Průměr ≥ 0,8. DumbRouteResolver skončí pod prahem (eval umí selhat). |

## Golden set (F4)
- Postup a historie skóre: `docs/EVAL.md`.
- Případy jsou v `PrelezTests/GoldenSet.swift`. Každý má formulaci, očekávanou cestu (nebo „žádná“ / „nejednoznačné“)
  a volitelně očekávaný výsledek.
- Zatím pracujeme s **ukázkovými daty** (`Resources/routes-sample.json`). Až přijde export od stavěčů:
  - přepsat případy na reálné cesty Vertikonu a doplnit reálné formulace lezců z baru;
  - snapshot zmrazit k datu, aby eval po přestavbě nepřestal dávat smysl.
- Skóre případu = 0,7 · správná cesta + 0,3 · správný výsledek (když ho případ určuje).
  Chyba nebo výjimka = 0. Každý případ běží 3×, sledujeme průměr i nejhorší běh.

## Predikce: co agent pravděpodobně zvorá
1. Porovná obtížnosti bez ohledu na velikost písmen a sloučí 6b s 6B.
2. Po odstranění diakritiky splete „šedá“ (`seda`) se „sedmičkou“.
3. V App Intentu ukládá přes `try?` a chyba se ztratí.
4. Při importu snapshotu smaže staré cesty i s pokusy (cascade).
5. Model vrátí ID cesty, která mezi kandidáty není (halucinace).
6. Intent si vytvoří vlastní `ModelContainer` a appka jeho zápis neuvidí.
