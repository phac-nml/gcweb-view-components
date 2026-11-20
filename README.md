# GCWeb View Components

Rails components that render [GCWeb](https://github.com/wet-boew/GCWeb) / [WET-BOEW](https://github.com/wet-boew/wet-boew) markup and look exactly like Canada.ca, built with [ViewComponent](https://viewcomponent.org) and [Stimulus](https://stimulus.hotwired.dev).

- **Same markup as GCWeb.** Components output GCWeb's HTML and class names, so the [GCWeb documentation](https://wet-boew.github.io/GCWeb/) applies directly.
- **Same look as GCWeb.** Styles are hand-written SCSS whose computed values are checked against GCWeb's own demo pages (currently **GCWeb v20.0.1**).
- **No jQuery, no wet-boew.js.** Interactive behaviour is ported to Stimulus controllers.
- **CSP-friendly.** Nothing renders inline `style=""` attributes; fonts are self-hosted.
- **Bilingual.** English and French strings ship with the gem.

## Components

| Component | GCWeb reference | Stimulus |
| --- | --- | --- |
| `Gcweb::AlertComponent` | [Alert](https://wet-boew.github.io/GCWeb/common/alert/alert-docs-en.html) | – |
| `Gcweb::FeaturedLinkComponent` | [Featured link](https://wet-boew.github.io/GCWeb/components/gc-featured-link/gc-featured-link-doc-en.html) | `gcweb--featured-link` |
| `Gcweb::Form::TextFieldComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::TextAreaComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::SelectComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::RadiosComponent` | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |
| `Gcweb::Form::CheckboxesComponent` | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |
| `Gcweb::Form::CheckboxComponent` (tickbox) | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |

Every component has Lookbook previews (one scenario per GCWeb example, EN/FR toggle in the toolbar).

## Using the gem

```ruby
# Gemfile
gem "gcweb_view_components", github: "phac-nml/gcweb-view-components"
```

```erb
<%= render Gcweb::AlertComponent.new(variant: :warning, heading: "Warning alert") do %>
  <p>Alert details.</p>
<% end %>

<%= render Gcweb::AlertComponent.new(variant: :info, heading: "Canada Groceries and Essentials Benefit", collapsible: true) do %>
  <p>…</p>
<% end %>

<%= render Gcweb::FeaturedLinkComponent.new(href: "/promo", link_text: "[Promotion title]", background_color: "#005B61") %>
```

### Forms

`Gcweb::FormBuilder` renders GCWeb form groups (label, red asterisk and "(required)", hint, inline error) from a model. It is **opt-in**: the gem never changes `ActionView::Base.default_form_builder`, so it can sit next to another library's builder.

```erb
<%= gcweb_form_with model: @contact do |f| %>
  <%= f.text_field_group :first_name %>
  <%= f.text_field_group :email, type: :email, hint: "(yourname@domain.com)" %>
  <%= f.text_area_group :post_nominals, rows: 4 %>
  <%= f.select_group :preferred_language, [ [ "English", "en" ], [ "French", "fr" ] ], prompt: true %>
  <%= f.radio_buttons_group :contact_method, [ [ "Email", "email" ], [ "Phone", "phone" ] ] %>
  <%= f.check_boxes_group :topics, [ [ "Health", "health" ], [ "Science", "science" ] ] %>
  <%= f.check_box_group :terms %>
  <%= f.text_field :internal_ref %>  <%# Rails' own methods are unchanged %>
<% end %>
```

`gcweb_form_with` is `form_with(builder: Gcweb::FormBuilder)`. The builder reads the label from `human_attribute_name`, marks a field required when it has an unconditional presence (or, for `check_box_group`, acceptance) validator, and shows `model.errors` with the markup wet-boew's form validation uses ("Error 1: …"), so server-side errors look like GCWeb's client-side ones. Every inferred value can be overridden (`label:`, `required:`, `hint:`, `error:`, `id:`, …), and other options become attributes on the control.

Radio buttons and checkboxes use GCWeb's large `gc-chckbxrdio` style in a fieldset, with the question, required marker and error in the legend. `inline: true` puts the options in a row and `disabled: [values]` disables some of them. Checkbox groups submit an array (`name[]`), and both send an empty value when nothing is chosen, as Rails' collection helpers do.

The components work without a model too:

```erb
<%= render Gcweb::Form::TextFieldComponent.new(name: "email", label: "Email", type: :email, required: true) %>
```

### Styles

Two stylesheets are provided, both prebuilt as plain CSS next to their SCSS source in `app/assets/stylesheets/gcweb_view_components/`:

| File | Contains | Use when |
| --- | --- | --- |
| `gcweb.css` | tokens, fonts, GCWeb base typography, components | the app should look like a Canada.ca page |
| `gcweb-components.css` | tokens, fonts, components (no global element styles) | the app keeps its own base, e.g. Tailwind / Pathogen apps |

**Vite / esbuild apps** resolve the gem path with `bundle show gcweb_view_components` (as irida-next does for Pathogen), alias it, and import the CSS or the SCSS source. `demo/vite.config.ts` is a working example:

```js
// vite.config.ts
const gemRoot = execFileSync("bundle", ["show", "gcweb_view_components"]).toString().trim()
resolve: {
  alias: {
    gcweb_view_components: `${gemRoot}/app/assets/javascripts/gcweb_view_components/index.js`,
    "gcweb_view_components-scss": `${gemRoot}/app/assets/stylesheets/gcweb_view_components`
  }
}

// application.js
import "gcweb_view_components-scss/gcweb.scss" // or gcweb-components.scss
```

**Propshaft apps** can link the prebuilt file directly:

```erb
<%= stylesheet_link_tag "gcweb_view_components/gcweb" %>
```

Colours, fonts and spacing are exposed as CSS custom properties (`--gcweb-*`, see `_tokens.scss`).

### Stimulus controllers

```js
import { Application } from "@hotwired/stimulus"
import { registerGcwebControllers } from "gcweb_view_components" // app/assets/javascripts/gcweb_view_components/index.js

const application = Application.start()
registerGcwebControllers(application)
```

## Developing

The toolchain (Ruby from `.ruby-version`, Node 24, pnpm via Corepack) comes from [devenv](https://devenv.sh), loaded automatically by [direnv](https://direnv.net), the same setup as irida-next. After cloning, allow it once:

```bash
direnv allow .
```

Without direnv, `devenv shell` gives the same environment.

```bash
bundle install
```

```bash
pnpm install
```

```bash
bin/dev
```

`bin/dev` starts the Lookbook demo app at http://127.0.0.1:3100/lookbook (`PORT=3200 bin/dev` to change).
### Layout

```
app/components/gcweb/                       ViewComponents (the gem)
app/assets/stylesheets/gcweb_view_components/  SCSS sources, compiled CSS, fonts
app/assets/javascripts/gcweb_view_components/  Stimulus controllers
config/locales/                             gem EN/FR strings
demo/                                       Rails app hosting Lookbook (not shipped)
test/components/previews/                   Lookbook previews
test/gcweb_reference/                       GCWeb computed-style snapshot for parity checks
```

### Checks

| Command | What it checks |
| --- | --- |
| `bundle exec rake test` | component and preview tests (EN + FR) |
| `pnpm test` | Stimulus controller tests (Vitest) |
| `pnpm build:css` | recompile `gcweb.css` / `gcweb-components.css` after SCSS changes (CI runs `build:css:check`) |
| `pnpm preview:check` | starts the demo, then runs GCWeb parity, axe (WCAG 2.1 AA) and visual regression |
| `pnpm parity:live` | compares previews against the live GCWeb demo site (needs a running demo) |

**GCWeb parity** is how "looks just like GCWeb" is enforced. `scripts/check_gcweb_parity.mjs` pairs elements on GCWeb's demo pages with the same elements in our previews and compares every computed CSS value that defines the look. The GCWeb side is a committed snapshot (`test/gcweb_reference/gcweb-<version>.json`), so CI is offline and OS-independent. When moving to a new GCWeb release, bump `GCWEB_VERSION` in `lib/gcweb_view_components/version.rb`, run `pnpm parity:capture`, and fix the differences.

### Adding a component

1. Read the component's GCWeb source (`components/<name>/` or `common/<name>/` in the GCWeb repo) and its demo page.
2. Read GCWeb's real values with `node scripts/computed_styles.mjs <demo url> <selectors…>`.
3. Add `app/components/gcweb/<name>_component.{rb,html.erb}` rendering GCWeb's exact markup, plus a partial in `stylesheets/gcweb_view_components/components/`.
4. Port any wet-boew/GCWeb JavaScript to a Stimulus controller under `javascripts/gcweb_view_components/controllers/` and register it in `index.js`.
5. Add a preview with one scenario per GCWeb example, using GCWeb's EN/FR demo text in `demo/config/locales/previews.*.yml`.
6. Add parity checks for it in `scripts/check_gcweb_parity.mjs` and its routes in `scripts/preview_routes.mjs`, then `pnpm parity:capture`.

## License

[Apache License 2.0](LICENSE), the same as other phac-nml projects.

The bundled fonts in `app/assets/stylesheets/gcweb_view_components/fonts/` have their own licences, which are included next to them: Lato and Noto Sans under the SIL Open Font License, and the Glyphicons subset under WET-BOEW's MIT licence. GCWeb and WET-BOEW are © the Government of Canada, MIT licensed.
