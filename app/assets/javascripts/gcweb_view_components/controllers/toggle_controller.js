import { Controller } from "@hotwired/stimulus"

// Port of wet-boew's toggle plugin (wb-toggle, GCWeb v20.0.1), without
// jQuery. Put it on the element people click and configure it with the
// same data-toggle JSON GCWeb uses:
//
//   <button type="button" class="btn btn-default wb-toggle"
//           data-controller="gcweb--toggle"
//           data-toggle='{"selector": "details", "parent": "#faq", "type": "on"}'>Expand all</button>
//
// Options (all optional):
// - selector: the elements it toggles (default: the element itself; on a
//   <summary>, its <details>)
// - parent: only toggle elements inside this
// - group: only one element matching it is on at a time; with parent, the
//   group is an accordion (summaries toggle their own details)
// - type: "on" or "off" to only turn elements on or off
// - state: the initial state ("off" by default)
// - stateOn / stateOff: classes for each state ("on" / "off")
// - persist: "session" or "local" to keep the state across page loads
//   (needs an id on the element, part of the storage key)
// - print: "on" or "off" to set the state before printing
//
// Toggled elements get the stateOn/stateOff class, and <details> open or
// close. The element gets aria-controls listing them. Each change dispatches
// "gcweb--toggle:toggled" with { isOn, elements }.
//
// wet-boew makes an accordion a tablist (role=tab wrappers around each
// <details>); this keeps native <details> semantics.

const DEFAULTS = { stateOn: "on", stateOff: "off" }
const STORAGE_PREFIX = "wb-toggle"
let generatedIds = 0

// wet-boew remembers the state of each selector (per parent) for the page,
// so a "Toggle" button knows what it last did. Keyed by <body>, which Turbo
// replaces on each visit.
const pageStates = new WeakMap()
const statesFor = () => {
  if (!pageStates.has(document.body)) pageStates.set(document.body, {})
  return pageStates.get(document.body)
}

// The state of a toggle that controls itself.
const elementStates = new WeakMap()

export function parseOptions(json) {
  if (!json) return { ...DEFAULTS }
  try {
    return { ...DEFAULTS, ...JSON.parse(json) }
  } catch {
    console.warn("gcweb--toggle: data-toggle isn't valid JSON", json)
    return { ...DEFAULTS }
  }
}

export default class extends Controller {
  connect() {
    this.options = parseOptions(this.element.dataset.toggle)
    this.setAriaControls()

    const restored = this.options.persist ? this.restore() : null
    if (!restored && this.options.state) this.setState([this.element], this.options, this.options.state)

    if (this.options.print) {
      this.beforePrint = () => this.toggle({ ...this.options, type: this.options.print })
      window.addEventListener("beforeprint", this.beforePrint)
    }

    this.onClick = (event) => this.click(event)
    this.element.addEventListener("click", this.onClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
    if (this.beforePrint) window.removeEventListener("beforeprint", this.beforePrint)
  }

  get isAccordion() {
    return Boolean(this.options.group && this.options.parent)
  }

  get storage() {
    try {
      return this.options.persist === "session" ? window.sessionStorage : window.localStorage
    } catch {
      return null
    }
  }

  get storageKey() {
    return STORAGE_PREFIX + (this.options.group || "") + this.element.id
  }

  click(event) {
    event.preventDefault()
    this.toggle(this.options)
    this.element.focus()
  }

  toggle(options) {
    const { stateOn, stateOff } = options
    const stateFrom = this.getState(options)
    const isOn = stateFrom === stateOff
    const stateTo = isOn ? stateOn : stateOff
    const elements = this.isAccordion ? this.accordionPanel() : this.elements(options)

    if (options.group) {
      const groupOptions = { ...options, selector: options.group }
      const groupElements = this.elements(groupOptions)
      const groupTabs = this.isAccordion ? this.accordionTabs() : groupElements
      this.setState(groupTabs, groupOptions, stateOff)
      groupElements.forEach((element) => this.apply(element, stateOff, stateOn))
      if (options.persist) this.forgetGroup(options.group)
    }

    this.setState(this.isAccordion ? [this.element] : elements, options, stateTo)
    elements.forEach((element) => this.apply(element, stateTo, stateFrom))

    if (options.persist) {
      try {
        this.storage?.setItem(this.storageKey, stateTo)
      } catch {
        // Storage can be full or blocked; the state just isn't kept.
      }
    }

    this.dispatch("toggled", { detail: { isOn, elements } })
  }

  // Swaps the state classes; <details> (or a <summary>'s <details>) open or close.
  apply(element, stateTo, stateFrom) {
    element.classList.remove(stateFrom)
    element.classList.add(stateTo)
    const details = element.localName === "summary" ? element.parentElement : element
    if (details?.localName === "details") details.open = stateTo === this.options.stateOn
  }

  elements(options) {
    if (!options.selector) return [this.element]
    const roots = options.parent ? [...document.querySelectorAll(options.parent)] : [document]
    return roots.flatMap((root) => [...root.querySelectorAll(options.selector)])
  }

  // In an accordion a summary toggles the group member it's in.
  accordionPanel() {
    const panel = this.element.parentElement?.closest(this.options.group)
    return panel ? [panel] : []
  }

  accordionTabs() {
    const parents = [...document.querySelectorAll(this.options.parent)]
    return parents.flatMap((parent) => [...parent.querySelectorAll(`${this.options.group} .tgl-tab`)])
  }

  // wet-boew's getState: the state the elements are in now, which toggle reverses.
  getState(options) {
    const { selector, parent, type, stateOn, stateOff } = options
    if (type) return type === "on" ? stateOff : stateOn
    if (this.element.localName === "summary") return this.element.parentElement?.open ? stateOn : stateOff
    if (!selector) return elementStates.get(this.element) || stateOff
    if (selector === "details") {
      return this.elements(options).some((details) => !details.open) ? stateOff : stateOn
    }
    const states = statesFor()[selector]
    if (states) return Object.hasOwn(states, parent) ? states[parent] : states.all
    return stateOff
  }

  setState(elements, options, state) {
    const { selector, parent, stateOff } = options
    if (selector) {
      const states = statesFor()
      states[selector] ||= { all: stateOff }
      if (parent) {
        states[selector][parent] = state
      } else {
        // A toggle for the whole page also sets the parent-restricted ones.
        for (const key of Object.keys(states[selector])) states[selector][key] = state
      }
    }
    elements.forEach((element) => elementStates.set(element, state))
  }

  setAriaControls() {
    if (this.isAccordion || !this.options.selector) return
    const ids = this.elements(this.options).map((element) => {
      if (!element.id) element.id = `gcweb-toggle-${++generatedIds}`
      return element.id
    })
    if (ids.length) this.element.setAttribute("aria-controls", ids.join(" "))
  }

  restore() {
    if (!this.element.id) {
      console.warn("gcweb--toggle: persist needs an id on the toggle element", this.element)
      return null
    }
    let state = null
    try {
      state = this.storage?.getItem(this.storageKey)
    } catch {
      return null
    }
    if (state) this.toggle({ ...this.options, type: state })
    return state
  }

  forgetGroup(group) {
    const storage = this.storage
    if (!storage) return
    const prefix = STORAGE_PREFIX + group
    for (const key of Object.keys(storage)) {
      if (key.startsWith(prefix)) storage.removeItem(key)
    }
  }
}
