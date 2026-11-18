# GCWeb View Components

Rails implementation of GCWeb/WET-inspired UI patterns using modern Rails and JavaScript tooling.

## Stack
- Ruby + Rails 8
- ViewComponent
- Hotwire (Turbo + Stimulus)
- Vite Ruby

## Project goal
Recreate key GCWeb template behavior and structure with:
- WCAG AA baseline checks
- EN/FR support
- SSR-first pages with progressive enhancement

## Current status
Wave 1 work in progress:
- Baseline fixtures and screenshots in [`fixtures/wave-1/`](./fixtures/wave-1/)
- Home and content template parity started
- Global shell (skip links, header, language switch, footer) in place

## Run locally
```bash
bundle install
npm install
bin/dev
```

Default dev port is `3100` (override with `PORT=3200 bin/dev`).

## Quality checks
```bash
bundle exec rails test
npm run preview:check
```

`preview:check` runs accessibility checks and visual regression checks.
