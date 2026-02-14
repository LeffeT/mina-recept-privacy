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
