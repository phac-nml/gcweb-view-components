# Wave 1 baseline fixtures

This folder stores reference fixtures for Wave 1 parity work.

## Included
- `pages/`: raw HTML snapshots from GCWeb reference templates (EN/FR)
- `screenshots/`: baseline PNG captures for visual regression inputs
- `manifest.json`: canonical source/target map for each fixture
- `interaction-notes.md`: expected interaction behavior (menu/toggle focus states)

## Refresh
Run:

```bash
bash scripts/capture_wave1_baseline.sh --with-screenshots
```
