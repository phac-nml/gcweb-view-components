import { Controller } from "@hotwired/stimulus"

// Port of wet-boew's tabbed interface (wb-tabs, GCWeb v20.0.1), without
// jQuery and without the carousel.
//
//   <div class="wb-tabs" id="…" data-controller="gcweb--tabs">
//     <div class="tabpanels">
//       <details id="panel1"><summary>Tab 1</summary><div class="tgl-panel">…</div></details>
//       <details id="panel2" open><summary>Tab 2</summary><div class="tgl-panel">…</div></details>
//     </div>
//   </div>
//
// On screens 992px and wider it adds wb-tabs' tab list (ul[role=tablist]
// with a link per panel) and shows one panel at a time. Under 992px the
// tab list is hidden and the panels are an accordion: one open at a time,
// any of them closable. wet-boew gives the summaries tab roles there; this
// keeps them native <details> disclosures (grouped with the name
// attribute), which screen readers already announce.
//
// Like wb-tabs:
// - the first panel shown is the one the URL hash names (or contains the
//   hash's target), else the last one chosen this session, else the open
//   one, else the first;
// - the last panel chosen is kept in sessionStorage under
//   "<path>#<container id>-activePanel" unless the container has the
//   ignore-session class;
// - arrow keys move between tabs, Enter/Space moves focus into the panel
//   and Ctrl+Up moves from a panel back to its tab;
// - links to a panel's id inside the panels, and links with the
//   wb-tabs-ext class anywhere on the page, open that panel;
// - the update-hash class puts the open panel's id in the URL.
//
// After a change it dispatches "gcweb--tabs:change" with { panel }.

export const SMALL_VIEW = "screen and (max-width: 991px)"
const PREVIOUS_KEYS = ["ArrowLeft", "ArrowUp"]
const NEXT_KEYS = ["ArrowRight", "ArrowDown"]

export default class extends Controller {
  connect() {
    // A Turbo snapshot keeps the generated tab list; build it again.
    this.element.querySelector(":scope > ul.generated")?.remove()
    this.panels = [...this.element.querySelectorAll(":scope > .tabpanels > details")]
    if (this.panels.length === 0) return

    this.panels.forEach((panel) => this.preparePanel(panel))
    this.tablist = this.buildTablist()
    this.element.prepend(this.tablist)
    this.element.classList.add("wb-init", "wb-tabs-inited", "tabs-acc")

    const first = this.initialPanel()
    this.activeId = first.id
    if (this.hashNamesPanel) this.store(first)

    this.media = window.matchMedia(SMALL_VIEW)
    this.smallView = this.media.matches
    this.render()
    if (this.updateHash) this.writeHash(first)

    this.listen(this.media, "change", () => this.viewChanged())
    this.listen(this.tablist, "click", (event) => this.tabClicked(event))
    this.listen(this.tablist, "keydown", (event) => this.tabKeydown(event))
    this.listen(this.element, "keydown", (event) => this.panelKeydown(event))
    this.listen(this.element, "click", (event) => this.panelLinkClicked(event))
    this.listen(this.element, "toggle", (event) => this.panelToggled(event), true)
    this.listen(document, "click", (event) => this.externalLinkClicked(event))
  }

  disconnect() {
    this.listeners?.forEach(([target, type, handler, capture]) => target.removeEventListener(type, handler, capture))
    this.listeners = []
  }

  get ignoreSession() {
    return this.element.classList.contains("ignore-session")
  }

  get updateHash() {
    return this.element.classList.contains("update-hash")
  }

  get storageKey() {
    return `${window.location.pathname}#${this.element.id}-activePanel`
  }

  listen(target, type, handler, capture = false) {
    target.addEventListener(type, handler, capture)
    ;(this.listeners ||= []).push([target, type, handler, capture])
  }

  // wb-tabs wraps each panel's content in div.tgl-panel and marks the summary
  // as a toggle; the component renders the wrapper, plain markup may not.
  preparePanel(panel) {
    const summary = panel.querySelector(":scope > summary")
    summary?.classList.add("wb-toggle", "tgl-tab")
    if (!panel.querySelector(":scope > .tgl-panel")) {
      const wrapper = document.createElement("div")
      wrapper.className = "tgl-panel"
      wrapper.append(...[...panel.childNodes].filter((node) => node !== summary))
      panel.append(wrapper)
    }
  }

  buildTablist() {
    const list = document.createElement("ul")
    list.setAttribute("role", "tablist")
    list.setAttribute("aria-live", "off")
    list.className = "generated"
    for (const panel of this.panels) {
      const item = document.createElement("li")
      item.setAttribute("role", "presentation")
      const link = document.createElement("a")
      link.id = `${panel.id}-lnk`
      link.href = `#${panel.id}`
      link.setAttribute("role", "tab")
      link.setAttribute("aria-controls", panel.id)
      link.innerHTML = panel.querySelector(":scope > summary")?.innerHTML ?? ""
      item.append(link)
      list.append(item)
    }
    return list
  }

  initialPanel() {
    const hash = decodeURIComponent(window.location.hash.slice(1))
    this.hashNamesPanel = false
    if (hash) {
      const named = this.panels.find((panel) => panel.id === hash)
      if (named) {
        this.hashNamesPanel = true
        return named
      }
      const target = document.getElementById(hash)
      const containing = target && this.panels.find((panel) => panel.contains(target))
      if (containing) return containing
    }
    if (!this.ignoreSession) {
      const stored = this.read()
      const remembered = stored && this.panels.find((panel) => panel.id === stored)
      if (remembered) return remembered
    }
    return this.panels.find((panel) => panel.open) || this.panels[0]
  }

  // Applies the current view to every panel, tab and summary.
  render() {
    this.tablist.setAttribute("aria-hidden", String(this.smallView))
    this.panels.forEach((panel, index) => {
      const active = panel.id === this.activeId
      const summary = panel.querySelector(":scope > summary")
      const tglPanel = panel.querySelector(":scope > .tgl-panel")
      const link = this.tablist.children[index].firstElementChild
      this.tablist.children[index].classList.toggle("active", active)
      link.setAttribute("aria-selected", String(active))
      link.tabIndex = active ? 0 : -1

      if (this.smallView) {
        // Close the others before grouping, so the group keeps this one open.
        panel.classList.remove("fade", "in", "out", "noheight")
        for (const name of ["role", "aria-hidden", "aria-expanded", "aria-labelledby"]) panel.removeAttribute(name)
        panel.open = active
        panel.setAttribute("name", `${this.element.id}-grp`)
        summary?.removeAttribute("aria-hidden")
        summary?.removeAttribute("tabindex")
      } else {
        // Ungroup first: grouped details close each other when opened.
        panel.removeAttribute("name")
        panel.open = true
        panel.setAttribute("role", "tabpanel")
        panel.setAttribute("aria-labelledby", link.id)
        panel.setAttribute("aria-hidden", String(!active))
        panel.setAttribute("aria-expanded", String(active))
        panel.classList.add("fade")
        panel.classList.toggle("in", active)
        panel.classList.toggle("out", !active)
        panel.classList.toggle("noheight", !active)
        summary?.setAttribute("aria-hidden", "true")
        summary?.setAttribute("tabindex", "-1")
      }
      tglPanel?.removeAttribute("role")
    })
  }

  viewChanged() {
    this.smallView = this.media.matches
    // Back on a wide screen, show the accordion's open panel, else the first.
    if (!this.smallView) {
      this.activeId = (this.panels.find((panel) => panel.open) || this.panels[0]).id
    }
    this.render()
  }

  // Shows a panel. Options: focus "tab", "panel" or "summary".
  select(panel, { focus } = {}) {
    const changed = panel.id !== this.activeId
    this.activeId = panel.id
    if (this.smallView) {
      panel.open = true
    } else {
      this.render()
    }
    if (focus === "tab") this.tabFor(panel).focus()
    if (focus === "panel") this.focusPanel(panel)
    if (focus === "summary") panel.querySelector(":scope > summary")?.focus()
    if (changed) this.changed(panel)
  }

  changed(panel) {
    this.store(panel)
    if (this.updateHash) this.writeHash(panel)
    this.dispatch("change", { detail: { panel } })
  }

  tabFor(panel) {
    return this.tablist.children[this.panels.indexOf(panel)].firstElementChild
  }

  panelForTab(tab) {
    return this.panels.find((panel) => panel.id === tab.getAttribute("aria-controls"))
  }

  focusPanel(panel) {
    if (!panel.hasAttribute("tabindex")) panel.tabIndex = -1
    panel.focus()
  }

  tabClicked(event) {
    const tab = event.target.closest("[role=tab]")
    if (!tab || event.button !== 0 || this.modified(event)) return
    event.preventDefault()
    this.select(this.panelForTab(tab))
  }

  tabKeydown(event) {
    const tab = event.target.closest("[role=tab]")
    if (!tab || this.modified(event)) return
    const index = this.panels.indexOf(this.panelForTab(tab))

    if (PREVIOUS_KEYS.includes(event.key) || NEXT_KEYS.includes(event.key)) {
      event.preventDefault()
      const step = PREVIOUS_KEYS.includes(event.key) ? -1 : 1
      const next = this.panels[(index + step + this.panels.length) % this.panels.length]
      this.select(next, { focus: "tab" })
    } else if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.select(this.panels[index], { focus: "panel" })
    } else if (event.key === "Escape") {
      event.preventDefault()
    }
  }

  // Ctrl+Up from inside a panel goes back to its tab (or its summary).
  panelKeydown(event) {
    if (!(event.ctrlKey && event.key === "ArrowUp")) return
    if (event.target.closest("[role=tablist]")) return
    const panel = this.panels.find((candidate) => candidate.contains(event.target))
    if (!panel || event.target === panel.querySelector(":scope > summary")) return
    event.preventDefault()
    if (this.smallView) {
      panel.querySelector(":scope > summary")?.focus()
    } else {
      this.tabFor(panel).focus()
    }
  }

  // A link inside the panels to another panel's id opens that panel.
  panelLinkClicked(event) {
    const link = event.target.closest(".tabpanels a[href^='#']")
    if (!link || event.button !== 0 || this.modified(event)) return
    const panel = this.panelForHref(link.getAttribute("href"))
    if (!panel) return
    event.preventDefault()
    this.select(panel, { focus: this.smallView ? "summary" : "tab" })
  }

  // a.wb-tabs-ext anywhere on the page opens the panel it points to.
  externalLinkClicked(event) {
    const link = event.target.closest?.("a.wb-tabs-ext")
    if (!link || event.button !== 0 || this.modified(event)) return
    const panel = this.panelForHref(link.getAttribute("href"))
    if (!panel) return
    event.preventDefault()
    this.select(panel, { focus: this.smallView ? "summary" : "tab" })
  }

  // In the accordion, opening a panel makes it the one remembered.
  panelToggled(event) {
    const panel = event.target
    if (!this.smallView || !this.panels.includes(panel) || !panel.open) return
    if (panel.id === this.activeId) return
    this.activeId = panel.id
    this.changed(panel)
  }

  panelForHref(href) {
    if (!href || href.length < 2) return null
    const id = decodeURIComponent(href.slice(1))
    return this.panels.find((panel) => panel.id === id) || null
  }

  modified(event) {
    return event.ctrlKey || event.altKey || event.metaKey
  }

  read() {
    try {
      return window.sessionStorage.getItem(this.storageKey)
    } catch {
      return null
    }
  }

  store(panel) {
    if (this.ignoreSession) return
    try {
      window.sessionStorage.setItem(this.storageKey, panel.id)
    } catch {
      // Storage can be unavailable (private mode, blocked); nothing to keep.
    }
  }

  // wb-tabs sets location.hash; replaceState does the same without
  // scrolling or adding a history entry per tab.
  writeHash(panel) {
    window.history.replaceState(window.history.state, "", `#${panel.id}`)
  }
}
