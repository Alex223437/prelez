# Eval rychlého zápisu (F4, A12)

- **Golden set:** `PrelezTests/GoldenSet.swift`, 28 případů nad ukázkovými daty.
- **Skóre případu:** 0,7 · správná cesta + 0,3 · správný výsledek. Chyba = 0.
- **Běhy:** každý případ běží 3×.
- **Práh:** průměr ≥ 0,8.
- **Spuštění:**
  ```sh
  xcodebuild -project Prelez.xcodeproj -scheme Prelez -destination 'platform=macOS,arch=arm64' test \
    -only-testing:PrelezTests/RouteResolverEvalTests
  ```
  Tabulky s odpověďmi jsou ve výpisu testu.

Eval umí selhat: `DumbRouteResolver` (vždy „první cesta, přelez“) má **0,17**, tedy hluboko pod prahem.

## Historie (hill-climbing)

| Verze | Změna | Pravidla | Hybrid | Co eval ukázal |
|---|---|---|---|---|
| v1 | Model vybírá cestu z kandidátů, české poznámky jdou do modelu | 0,87 | **0,83** | Regrese oproti pravidlům. Čeština: `unsupportedLanguageOrLocale`; „citronová“ → oranžová cesta. |
| v2 | Čeština jen pravidla + slovník `RouteTrait`, AI jen pro jiné jazyky | 0,86 | 0,89 | Model při výběru z kandidátů pořád vymýšlí („lemon colored“ → oranžová, „jump on the slab“ → R-04). |
| v3 | Model jen překládá do slovníku (barva, sektor, charakter, výsledek), cestu vybírají pravidla | 0,86 | **0,96** | Žádná vymyšlená cesta. Jediný bezpečný minus: „the one with the big jump outside“ zůstal na výběru ze 3 cest. |

Měřeno 14. 10. 2026 na macOS 26.6 (M3, Apple Intelligence zapnutá).
Model na zařízení podporuje da, de, en, es, fr, it, ja, ko, nb, nl, pt, sv, tr, vi, zh. **Čeština chybí.**

## Limity
- **Ukázková data.** Golden set je zatím nad vymyšlenými cestami. Až dorazí export od stavěčů:
  - přepsat na reálné cesty Vertikonu;
  - doplnit reálné formulace lezců z baru;
  - zmrazit snapshot k datu.
- **Greedy decoding.** Model používá `samplingMode: .greedy`, takže 3 běhy dávají stejný výsledek.
  Běhy necháváme kvůli změnám modelu mezi verzemi OS. Na macOS 27 ve škole eval spustit znovu a výsledky porovnat.
- **Hrubé kontroly.** Hodnotí se jen správná cesta a výsledek. Styl (RP/flash) má vlastní unit testy.
