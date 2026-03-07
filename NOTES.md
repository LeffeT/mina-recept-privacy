# Mina Recept – arbetsanteckningar

## Git & repo
- Projektet hade redan Git.
- Lade till `.gitignore` för Xcode, rensade `xcuserdata`/breakpoints.
- Satt remote, löste SSH‑nyckel, push.
- Delar av arbetet ligger på `feature/cloudkit-sharing`.

## Delning av recept (CloudKit)
- Delning sparas i Public CloudKit som `RecipeShare`.
- Import laddar från CloudKit om lokal/iCloud‑Drive payload saknas.
- Bild hämtas via `CKAsset`.
- Länkar fungerar för andra om:
  - samma miljö (Dev för Xcode, Prod för TestFlight)
  - rätt public‑behörigheter (`_icloud Create`, `_world Read`).

## Expiry + cleanup
- Länk får `expiresAt` (24h i kod).
- Import visar “länk utgången” om expired.
- Efter import försöker appen radera CloudKit‑record (funkar om samma Apple‑ID).
- Lokal städning av egna gamla records vid appstart.

## UI‑förbättring
- Tog bort dubbel länk i delning (bara en länk kvar).
- Lade iCloud‑statusindikator på startskärmen + “Senast synkat”.
- “Synkar…” hålls kvar minst 10 sek.

## Fixade varningar
- Main‑actor varning + switch‑exhaustive fix i `CloudSyncStatus`.

## Senaste ändringar (2026-02-14)
- SetupView redesign: header + temakort, språklista som rader, om‑sektion med version + iCloud‑status.
- Temanamnen är lokaliserade, “Svart” används för svart tema.
- Version/build hämtas nu från build‑inställningar (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).
- Vit tema tillagt, och textfärger följer tema (svart text i vitt tema).
- Bildladdning görs asynkront + cache för att undvika UI‑lagg.
- Import visar kort “Receptet importerades”‑bekräftelse.
- iCloud‑payload logg tystas när fil saknas (normalt vid CloudKit‑import).
- Portions‑stepper ersatt med egen plus/minus‑kontroll (ingen svart kant i vitt tema).
- Bytte `print` mot `os.Logger` via `AppLog` för filtrerbara loggar i Console.

## Senaste ändringar (2026-02-16)
- Delning/import: `baseServings` skickas med och sparas vid import.
- Placeholder‑text färg justerad för vit tema via `placeholderTextColor`.
- Stöd för bråk i mängd (t.ex. `1/2`, `1 1/2`) vid inmatning.
- Bevarar originaltext för mängd (`amountText`) i Core Data och delning.
- Delnings‑payload skickar med `amountText` så `1/2` inte blir `0,5`.
- “Recept” → “Gör så här” och “Ingredienser” rubrik tillagd (eng: Instructions/Ingredients).
- iCloud‑bilder: triggar nedladdning om filen finns men inte är läsbar.

## Senaste ändringar (2026-02-17)
- Portions‑kontrollen flyttad över ingredienslistan i `RecipeDetailView`.
- iCloud‑status uppdateras vid lokala saves/deletes (utan att gå tillbaka till StartView).

## Senaste ändringar (2026-02-27)
- Ingredienser kan delas upp i 3 kategorier (Add/Edit) med egna rubriker.
- Kategorinamn sparas på receptet (`group1Title`/`group2Title`/`group3Title`) och `groupIndex` sparas per ingrediens (Core Data‑schema uppdaterat).
- Delning/import skickar med kategori‑rubriker och `groupIndex` så grupperna bevaras.
- `RecipeDetailView` visar ingredienser per kategori i swipe‑vy (TabView) med egna dots och dynamisk höjd.
- “Gör så här” flyttad i Edit‑vyn så rubriken ligger precis ovanför instruktionstexten.
- Segment‑numren (1–3) i vitt tema tvingas till svart text.
- IAP‑stöd: 3 gratis recept, paywall och upplåsning via StoreKit 2 (non‑consumable).

## 2026-03-06
- Flyttade demo-seed/flush/cleanup från launch till HomeView; StartView kör bara varningar + fördröjd iCloud-refresh.
- Justerade StartView i landskap (maxbredd knapp).
- Fixade delade recept-importer genom explicit environment i sheet.
- Uppdaterade iCloud-varningstext + knapp (lokalisering) med steg inkl iCloud Drive och app-toggle.
- Lade in lagringsrapport + rensa oanvända bilder i Inställningar (med bekräftelse).
- Rensar orphanade bilder i iCloud/local via FileHelper.
- EditRecipeView sparar ny bild bara vid ändring och tar bort gammal fil (rollback vid fel).
- RecipeDetailView placeholder för “Ingen bild” syns tydligare.
- Fix för språk: cleanup-summary översätts dynamiskt.

