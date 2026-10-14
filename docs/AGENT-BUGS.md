# Co agent zvoral

Každá chyba, kterou udělal agent (Claude Code) a kterou jsme našli testem, buildem nebo klikáním.
Na obhajobě padne otázka: „Kód, který se přeložil, ale byl špatně. Jak jsi to zjistil?“

| # | Datum | Feature | Symptom | Jak jsem to našel | Oprava |
|---|---|---|---|---|---|
| 1 | 14. 10. 2026 | F4 | Kód se přeložil a appka „fungovala“, ale hybrid (pravidla + AI) měl horší skóre než samotná pravidla: **0,83 vs 0,87**. Problémy: české poznámky končily chybou `unsupportedLanguageOrLocale`, a „citronová v kolmici“ model přiřadil oranžové cestě. | Eval (3 běhy) s výpisem odpovědí. Pak ověření `SystemLanguageModel.default.supportsLocale(cs_CZ) == false`: model na zařízení češtinu neumí. | Češtinu řeší pravidla + slovník charakteru cest (`RouteTrait`). AI se volá jen pro jazyky, které model umí. Při chybě modelu se použijí pravidla a uživatel vidí důvod (`aiNote`). |
| 2 | 14. 10. 2026 | F4 | Krok „vyber cestu z kandidátů“ vybíral cesty, které poznámka nepopisuje: „lemon colored one“ → oranžová R-09, „jump on the slab“ → R-04 (na plotně žádné dyno není). Zapsal by se pokus na špatnou cestu. | Eval: případy `ai-en-lemon` a `ai-en-unsure-slab` měly skóre 0 ve všech 3 bězích. | Model už cestu nevybírá. Jen překládá text do pevného slovníku (barva, sektor, charakter, výsledek) a cestu najdou pravidla. Hybrid se zlepšil z 0,89 na 0,96 a žádná cesta už není vymyšlená. |
| 3 | 14. 10. 2026 | build | Testy nešly na macOS spustit: `TEST_HOST` ukazoval na iOS cestu `Prelez.app/Prelez`. | Hned první `xcodebuild test` na My Mac. | `TEST_HOST` s `$(BUNDLE_EXECUTABLE_FOLDER_PATH)` v `project.yml`. |
