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
