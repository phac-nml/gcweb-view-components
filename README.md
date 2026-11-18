# GCWeb View Components

Rails + ViewComponent workbench for building WET/GCWeb components in isolation.

## Stack
- Ruby + Rails 8
- ViewComponent
- Hotwire (Turbo + Stimulus)
- Vite Ruby
- Lookbook

## Project goal
Build pixel-accurate WET/GCWeb components (not full page templates), preview them in Lookbook, and validate with focused a11y/visual checks.

Current first component:
- Alert module preview aligned to GCWeb alert examples (`/rails/view_components/gcweb/alert_component/en`)
- Includes heading, link, no-heading, and expand/collapse alert patterns

## Run locally
```bash
bundle install
npm install
bin/dev
```

Default dev port is `3100` (override with `PORT=3200 bin/dev`).

Open:
- Workbench: `http://127.0.0.1:3100/`
- Lookbook: `http://127.0.0.1:3100/lookbook`

## WET source references (starter backlog)
- Alert module: https://wet-boew.github.io/wet-boew-legacy/v3.1/demos/guide-design/components-en.html#message-box-modules
- GCWeb component source index: https://github.com/wet-boew/GCWeb/tree/master/components
- Featured link: https://github.com/wet-boew/GCWeb/tree/master/components/gc-featured-link
- Most requested: https://github.com/wet-boew/GCWeb/tree/master/components/gc-most-requested

## Quality checks
```bash
bin/rails test
npm run preview:check
```

`preview:check` runs accessibility + visual regression on the workbench and component preview routes.
