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
| `Gcweb::ButtonComponent` | [Buttons](https://wet-boew.github.io/GCWeb/common/button/button-en.html) | – |
| `Gcweb::LabelComponent` | [Labels](https://wet-boew.github.io/GCWeb/components/labels/labels-en.html) | – |
| `Gcweb::BadgeComponent` | [Badges](https://wet-boew.github.io/GCWeb/components/badges/badges-en.html) | – |
| `Gcweb::PanelComponent` | [Panels](https://wet-boew.github.io/GCWeb/components/panels/panels-en.html) | – |
| `Gcweb::TableComponent` | [Tables](https://wet-boew.github.io/GCWeb/common/tables/table-en.html) | – |
| `Gcweb::WellComponent` | [Panels](https://wet-boew.github.io/GCWeb/components/panels/panels-en.html) (wells) | – |
| `Gcweb::TableOfContentsComponent` | [In-page table of contents](https://wet-boew.github.io/GCWeb/components/gc-toc/toc-en.html) | – |
| `Gcweb::ServicesAndInformationComponent` | [Services and information](https://wet-boew.github.io/GCWeb/components/gc-srvinfo/gc-srvinfo-en.html) | – |
| `Gcweb::MostRequestedComponent` | [Most requested](https://wet-boew.github.io/GCWeb/components/gc-most-requested/gc-most-requested-en.html) | – |
| `Gcweb::FeaturedLinkComponent` | [Featured link](https://wet-boew.github.io/GCWeb/components/gc-featured-link/gc-featured-link-doc-en.html) | `gcweb--featured-link` |
| `Gcweb::AccordionComponent` | [Toggle (accordion)](https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/toggle/toggle-en.html#accordion) | `gcweb--toggle` |
| `Gcweb::TabsComponent` | [Tabbed interface](https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/tabs/tabs-en.html) | `gcweb--tabs` |
| `Gcweb::OverlayComponent` | [Overlay](https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/overlay/overlay-en.html) | `gcweb--overlay` |
| `Gcweb::Form::TextFieldComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::TextAreaComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::SelectComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::RadiosComponent` | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |
| `Gcweb::Form::CheckboxesComponent` | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |
| `Gcweb::Form::CheckboxComponent` (tickbox) | [Checkboxes and radio buttons](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-doc-en.html) | – |
| `Gcweb::Form::FieldsetComponent` | [Forms](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html) | – |
| `Gcweb::Form::ErrorSummaryComponent` | [Form validation](https://wet-boew.github.io/wet-boew/docs/ref/formvalid/formvalid-en.html) | – |

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

<%= render Gcweb::ButtonComponent.new(variant: :primary, type: :submit).with_content("Submit") %>
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
  <%= f.fieldset_group legend: "Contact Address", heading: :h2 do %>
    <%= f.text_field_group :city %>
  <% end %>
  <%= f.fieldset_group :date_of_birth do %>
    <%= f.text_field_group :birth_year, size: 4 %>
    <%# … month and day %>
  <% end %>
  <%= f.text_field :internal_ref %>  <%# Rails' own methods are unchanged %>
<% end %>
```

`gcweb_form_with` is `form_with(builder: Gcweb::FormBuilder)`. The builder reads the label from `human_attribute_name`, marks a field required when it has an unconditional presence (or, for `check_box_group`, acceptance) validator, and shows `model.errors` with the markup wet-boew's form validation uses ("Error 1: …"), so server-side errors look like GCWeb's client-side ones. Every inferred value can be overridden (`label:`, `required:`, `hint:`, `error:`, `id:`, …), and other options become attributes on the control.

Radio buttons and checkboxes use GCWeb's large `gc-chckbxrdio` style in a fieldset, with the question, required marker and error in the legend. `inline: true` puts the options in a row and `disabled: [values]` disables some of them. Checkbox groups submit an array (`name[]`), and both send an empty value when nothing is chosen, as Rails' collection helpers do.

`fieldset_group` wraps its block's fields in a fieldset. Without an attribute it is a section of the form, with a plain legend (`heading: :h2` puts the text in a heading, as GCWeb's sections do, and `border: :bottom` is GCWeb's `legend-brdr-bttm`). With an attribute, the legend, required marker and error come from it, for an answer split over several fields but validated as one, such as a date. The `fieldset` and `legend` styles are global element styles, like `label`, so they are in `gcweb.css` only. Apps using `gcweb-components.css` get the required marker and error styles but keep their own fieldset and legend look.

When a field shows an error, `gcweb_form_with` puts an error summary at the top of the form, where wet-boew's validation puts it: "The form could not be submitted because 2 errors were found.", then a numbered link to each field. The form's fields are rendered first, so the numbers and links always match them. A checkbox or radio group's link goes to its first option, and a fieldset's to its legend. Errors the form didn't show (on `:base`, or on an attribute without a field) are listed last, without a link. The summary has `autofocus`, so after a failed submit it is focused first, as wb-frmvld does, and Turbo honours it too. Pass `error_summary: false` to leave it out, or `error_summary: { heading_level: 3 }` to change it. `Gcweb::Form::ErrorSummaryComponent` renders one on its own.

Forms from `gcweb_form_with` also check their fields in the browser before submitting, with the `gcweb--form-validation` Stimulus controller (a port of wet-boew's `wb-frmvld` built on the browser's Constraint Validation API). It shows the same inline errors and summary the server renders, with wet-boew's messages in the page's language ("This field is required.", "Please enter a valid email address.", …), and stops the submit until they're fixed. Like jQuery Validation, it checks everything on submit and focuses the summary. After that it rechecks fields as they're edited, updating the numbers and the summary. A checkbox group counts as required when its legend is marked required. The messages come from the gem's locale files (`gcweb.form.validation.*`), so apps can override them like any translation. The controller sets `novalidate` itself, so if the gem's controllers aren't registered, the browser's own validation still applies. Pass `validate: false` to leave it out.

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

| Identifier | Used by |
| --- | --- |
| `gcweb--featured-link` | `Gcweb::FeaturedLinkComponent` (background and text colours) |
| `gcweb--form-validation` | forms from `gcweb_form_with` (client-side validation) |
| `gcweb--overlay` | `Gcweb::OverlayComponent` (opening, focus, closing) |
| `gcweb--tabs` | `Gcweb::TabsComponent` (tab list, keyboard, accordion on small screens) |
| `gcweb--toggle` | `Gcweb::AccordionComponent`, and any element with GCWeb's `data-toggle` options |

`Gcweb::TabsComponent` renders the `<details>` panels GCWeb authors write, so without JavaScript they're expand/collapse sections. The `gcweb--tabs` controller (a port of wet-boew's `wb-tabs`) adds the tab list from 992px up and makes the panels an accordion below that, with wb-tabs' keyboard support (arrow keys, Enter/Space into the panel, Ctrl+Up back to the tab), session memory of the last tab (`ignore_session: true` to turn it off), URL hash support and `wb-tabs-ext` links. In the accordion the panels stay native `<details>` grouped with `name`, rather than wb-tabs' tab roles. The carousel variant isn't included yet.

`gcweb--toggle` is a port of wet-boew's `wb-toggle`. Put it on the element people click, with the same `data-toggle` JSON GCWeb uses (`selector`, `parent`, `group`, `type`, `state`, `stateOn`/`stateOff`, `persist`, `print`), so GCWeb markup works once `data-controller="gcweb--toggle"` is added. The `gcweb_toggle_data` view helper builds those attributes, for example for "Expand all" buttons:

```erb
<%= render Gcweb::ButtonComponent.new(class: "wb-toggle",
      data: gcweb_toggle_data(selector: "details", parent: "#faq", type: :on)) do %>
  Expand all
<% end %>
```

`Gcweb::OverlayComponent` renders GCWeb's overlays (`variant:` `:panel_left`, `:panel_right`, `:bar_top`, `:bar_bottom`, `:popup_mid` or `:popup_full`) with the close buttons wet-boew adds, and `gcweb_overlay_link_to` renders the links that open them:

```erb
<%= gcweb_overlay_link_to "Left panel", "left-panel" %>

<%= render Gcweb::OverlayComponent.new(id: "left-panel", title: "Left panel", variant: :panel_left) do %>
  <ul class="list-unstyled">…</ul>
<% end %>
```

The `gcweb--overlay` controller is a port of wet-boew's `wb-overlay`: it opens the overlay as a dialog and focuses it, keeps Tab inside, and closes it on Escape, on its close buttons, or on a click or focus outside it (`close_outside: false` for GCWeb's `outside-off`), returning focus to the link. Open or close one from your own code by dispatching `gcweb--overlay:open` or `gcweb--overlay:close` on it. Without JavaScript the overlays are shown in the page, as with GCWeb's noscript styles. wet-boew's Lightbox popups (`wb-lbx`) aren't included yet.

`Gcweb::AccordionComponent` renders GCWeb's accordion markup with it. As with tabs, the accordion keeps native `<details>` semantics (the sections share a `name`, so one stays open even without JavaScript) rather than wet-boew's tablist roles.

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
