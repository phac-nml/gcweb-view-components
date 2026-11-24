import { Controller } from "@hotwired/stimulus"

// Improves a Gcweb::DataTableComponent in a Turbo Frame (turbo_frame:):
// - filters as people type, after a pause
// - changes the page size on selection (the Apply button is hidden)
// - keeps focus and the filter's text when the frame's content is replaced
// - announces the new "Showing 1 to 10 of 57 entries" line
//
// It sits on an element around the frame, which isn't replaced. Without
// Turbo it does nothing, as each change would load the whole page.

const FILTER = ".dataTables_filter input[type=search]"
const PAGE_SIZE = ".dataTables_length select"
const PAGES = ".dataTables_paginate"

export default class extends Controller {
  static targets = ["frame", "status"]
  static classes = ["live"]
  static values = { delay: { type: Number, default: 300 }, pageParam: { type: String, default: "page" } }

  connect() {
    if (!customElements.get("turbo-frame")) return

    if (this.liveClasses.some((name) => this.element.classList.contains(name))) this.cleanSnapshot()

    this.element.classList.add(...this.liveClasses)
    this.listeners = [
      ["input", (event) => this.input(event)],
      ["compositionend", (event) => this.input(event)],
      ["change", (event) => this.change(event)],
      ["submit", (event) => this.submit(event)],
      ["click", (event) => this.click(event)],
      ["turbo:before-frame-render", (event) => this.beforeRender(event)],
      ["turbo:frame-render", (event) => this.afterRender(event)]
    ]
    // Capturing, to update links and forms before Turbo reads them.
    this.listeners.forEach(([name, listener]) => this.element.addEventListener(name, listener, true))
  }

  disconnect() {
    clearTimeout(this.timer)
    this.listeners?.forEach(([name, listener]) => this.element.removeEventListener(name, listener, true))
    this.listeners = null
    this.element.classList.remove(...this.liveClasses)
  }

  // Turbo's snapshots (Back and Forward) are clones made while this was
  // connected. Drops what they kept: typed text the table isn't filtered by,
  // and the busy state of the request that followed, which is never cleared.
  cleanSnapshot() {
    if (this.filter) this.filter.value = this.filter.defaultValue
    this.frameTarget.removeAttribute("busy")
    this.frameTarget.removeAttribute("aria-busy")
  }

  get filter() {
    return this.frameTarget.querySelector(FILTER)
  }

  // Typed text the server hasn't filtered by yet (its text is the value attribute).
  get unapplied() {
    return this.filter && this.filter.value !== this.filter.defaultValue
  }

  input(event) {
    if (event.target !== this.filter || event.isComposing) return
    this.scheduleFilter()
  }

  // Waits for a request in progress, so a sort or page size isn't lost.
  scheduleFilter() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      if (this.frameTarget.hasAttribute("busy")) this.scheduleFilter()
      else this.filter?.form.requestSubmit()
    }, this.delayValue)
  }

  change(event) {
    if (event.target.matches(PAGE_SIZE)) event.target.form.requestSubmit()
  }

  submit(event) {
    const form = event.target
    if (form.dataset.turboFrame !== this.frameTarget.id) return

    clearTimeout(this.timer)
    if (form === this.filter?.form || !this.unapplied) return

    let field = form.elements.namedItem(this.filter.name)
    if (!field) {
      field = Object.assign(document.createElement("input"), { type: "hidden", name: this.filter.name })
      form.append(field)
    }
    field.value = this.filter.value
  }

  // A sort or page link takes unapplied filter text with it, from page 1.
  click(event) {
    const link = event.target.closest("a[data-turbo-frame]")
    if (link?.dataset.turboFrame !== this.frameTarget.id || !this.unapplied) return

    clearTimeout(this.timer)
    const url = new URL(link.href)
    url.searchParams.set(this.filter.name, this.filter.value)
    url.searchParams.delete(this.pageParamValue)
    link.href = url.href
  }

  beforeRender(event) {
    if (event.target !== this.frameTarget) return

    const { filter } = this
    this.typed = this.unapplied ? filter.value : null
    this.selection = filter && document.activeElement === filter ? [filter.selectionStart, filter.selectionEnd] : null
    this.focusSelectors = this.frameTarget.contains(document.activeElement) ? selectorsFor(document.activeElement) : []
  }

  afterRender(event) {
    if (event.target !== this.frameTarget) return

    const { filter } = this
    if (filter && this.typed != null) filter.value = this.typed

    if (document.activeElement === document.body) {
      const selector = this.focusSelectors?.find((candidate) => this.frameTarget.querySelector(candidate))
      if (selector) this.frameTarget.querySelector(selector).focus({ preventScroll: true })
    }
    if (filter && this.selection && document.activeElement === filter) filter.setSelectionRange(...this.selection)

    this.typed = this.selection = null
    this.focusSelectors = []
    this.statusTarget.textContent = this.frameTarget.querySelector(".dataTables_info")?.textContent ?? ""
  }
}

// Where an element is in the table, to find its counterpart in the new one:
// the first selector that matches.
function selectorsFor(element) {
  if (element.matches(FILTER)) return [FILTER]
  if (element.matches(PAGE_SIZE)) return [PAGE_SIZE]

  if (element.closest(PAGES)) {
    const current = `${PAGES} [aria-current=page]`
    const rel = element.getAttribute("rel")
    return [...(rel ? [`${PAGES} a[rel=${rel}]`] : []), current, FILTER]
  }

  const heading = element.closest("table.dataTable > thead th")
  return heading ? [`table.dataTable > thead th:nth-child(${heading.cellIndex + 1}) a`] : []
}
