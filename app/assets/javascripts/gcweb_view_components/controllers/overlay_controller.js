import { Controller } from "@hotwired/stimulus"

// Port of wet-boew's overlay plugin (wb-overlay, GCWeb v20.0.1), without
// jQuery. Put it on the overlay <section> (Gcweb::OverlayComponent renders
// it); links to the overlay's id with the overlay-lnk class open it:
//
//   <a href="#left-panel" aria-controls="left-panel" class="overlay-lnk" role="button">Left panel</a>
//   <section id="left-panel" class="wb-overlay modal-content overlay-def wb-panel-l"
//            data-controller="gcweb--overlay">…</section>
//
// As in wet-boew:
// - opening adds the "open" class and role=dialog, focuses the overlay and
//   remembers the link; closing returns focus to it;
// - Tab and Shift+Tab wrap around inside the overlay;
// - Escape, the .overlay-close buttons, and a click or focus outside the
//   overlay close it (the "user-closed" class marks the first two);
// - a link inside the overlay to somewhere else on the page closes it and
//   focuses the link's target;
// - middle and full-screen popups set "wb-overlay-dlg" on <body> (no page
//   scrolling) and the page title for printing (data-pgtitle).
// With the outside-off class, outside activity doesn't close it and Tab can
// leave it; a bar then scrolls the page so the focused element isn't
// hidden behind it.
//
// Two differences: an open overlay also gets aria-modal (unless
// outside-off), since focus can't leave it, and closing it on outside
// activity leaves focus where the person put it rather than moving it back
// to the link.
//
// Open or close it from your own code with events:
//   overlay.dispatchEvent(new CustomEvent("gcweb--overlay:open"))
//   overlay.dispatchEvent(new CustomEvent("gcweb--overlay:close", { detail: { noFocus: true } }))
// Each change dispatches "gcweb--overlay:opened" or "gcweb--overlay:closed".

const FOCUSABLE = [
  "a[href]", "area[href]", "button", "input", "select", "textarea", "iframe",
  "summary", "[tabindex]", "[contenteditable]:not([contenteditable='false'])"
].join(", ")
const BODY_CLASS = "wb-overlay-dlg"
const POPUPS = ".wb-popup-mid, .wb-popup-full"

const isTabbable = (element) =>
  !element.disabled &&
  element.tabIndex >= 0 &&
  !element.closest("[hidden], [inert]") &&
  (typeof element.checkVisibility !== "function" || element.checkVisibility({ visibilityProperty: true }))

const focus = (element) => {
  if (!element.matches(FOCUSABLE) || element.tabIndex < 0) {
    if (!element.hasAttribute("tabindex")) element.setAttribute("tabindex", "-1")
  }
  element.focus()
}

export default class extends Controller {
  static values = { open: Boolean }

  connect() {
    this.sourceLink = null
    this.listeners = [
      [document, "click", (event) => this.documentClick(event)],
      [document, "keydown", (event) => this.documentKeydown(event)],
      [document, "focusin", (event) => this.outsideActivity(event)],
      [document, "keyup", () => this.keepFocusVisible()],
      [this.element, "keydown", (event) => this.keydown(event)],
      [this.element, "click", (event) => this.click(event)],
      [this.element, "gcweb--overlay:open", (event) => this.handleEvent(event, () => this.show({ focus: !event.detail?.noFocus }))],
      [this.element, "gcweb--overlay:close", (event) => this.handleEvent(event, () => this.hide({ focus: !event.detail?.noFocus }))]
    ]
    for (const [target, type, listener] of this.listeners) target.addEventListener(type, listener)

    this.element.setAttribute("aria-hidden", "true")
    if (this.openValue) this.show({ focus: false })
  }

  disconnect() {
    for (const [target, type, listener] of this.listeners) target.removeEventListener(type, listener)
    if (this.isOpen) this.hide({ focus: false })
  }

  // Actions, for buttons inside the overlay.
  open() {
    this.show()
  }

  close() {
    this.hide({ userClosed: true })
  }

  get isOpen() {
    return this.element.classList.contains("open")
  }

  get isPopup() {
    return this.element.matches(POPUPS)
  }

  get closesOnOutsideActivity() {
    return !this.element.classList.contains("outside-off")
  }

  show({ focus: moveFocus = true } = {}) {
    const overlay = this.element
    overlay.classList.add("open")
    overlay.setAttribute("role", "dialog")
    overlay.setAttribute("aria-hidden", "false")
    if (this.closesOnOutsideActivity) overlay.setAttribute("aria-modal", "true")

    if (this.isPopup) {
      const heading = document.querySelector("h1")
      if (heading) overlay.dataset.pgtitle = heading.textContent
      document.body.classList.add(BODY_CLASS)
    }

    if (moveFocus) {
      overlay.scrollTop = 0
      focus(overlay)
    }

    // The click that opened it is still on its way to the document; don't
    // count it as outside activity.
    this.justOpened = true
    setTimeout(() => { this.justOpened = false }, 0)

    this.dispatch("opened")
  }

  hide({ focus: moveFocus = true, userClosed = false } = {}) {
    if (!this.isOpen) return

    const overlay = this.element
    overlay.classList.remove("open")
    overlay.removeAttribute("role")
    overlay.removeAttribute("aria-modal")
    overlay.setAttribute("aria-hidden", "true")

    if (this.isPopup && !document.querySelector(`:is(${POPUPS}).open`)) {
      document.body.classList.remove(BODY_CLASS)
    }
    if (userClosed) overlay.classList.add("user-closed")

    const sourceLink = this.sourceLink
    this.sourceLink = null
    if (moveFocus && sourceLink?.isConnected) focus(sourceLink)

    this.dispatch("closed")
  }

  handleEvent(event, action) {
    if (event.target === this.element) action()
  }

  isLinkToOverlay(element) {
    const link = element?.closest?.("a.overlay-lnk")
    if (!link?.hash) return null
    return decodeURIComponent(link.hash.slice(1)) === this.element.id ? link : null
  }

  openFrom(link) {
    this.sourceLink = link
    this.show()
  }

  documentClick(event) {
    if (event.button) return // middle and right clicks

    const link = this.isLinkToOverlay(event.target)
    if (link) {
      event.preventDefault()
      this.openFrom(link)
      return
    }
    this.outsideActivity(event)
  }

  // overlay-lnk links have role=button, so Space opens them too.
  documentKeydown(event) {
    if (event.key !== " ") return
    const link = this.isLinkToOverlay(event.target)
    if (link) {
      event.preventDefault()
      this.openFrom(link)
    }
  }

  outsideActivity(event) {
    if (!this.isOpen || this.justOpened || !this.closesOnOutsideActivity) return
    const target = event.target
    if (target === this.element || this.element.contains(target) || this.isLinkToOverlay(target)) return
    this.hide({ focus: false })
  }

  keydown(event) {
    if (event.key === "Escape") {
      if (!event.defaultPrevented) this.hide({ userClosed: true })
    } else if (event.key === "Tab" && this.closesOnOutsideActivity) {
      this.wrapFocus(event)
    }
  }

  // wet-boew's Tab handling: from the overlay itself, or past either end,
  // focus goes to the other end.
  wrapFocus(event) {
    const tabbable = [...this.element.querySelectorAll(FOCUSABLE)].filter(isTabbable)
    const index = tabbable.indexOf(event.target) + (event.shiftKey ? -1 : 1)
    if (event.target !== this.element && index !== -1 && index !== tabbable.length) return

    event.preventDefault()
    const next = index < 0 ? tabbable.at(-1) : tabbable[0]
    if (next) focus(next)
  }

  click(event) {
    if (event.button) return

    if (event.target.closest(".overlay-close")) {
      this.hide({ userClosed: true })
      return
    }

    // A same-page link to outside the overlay: close it and focus the target.
    const link = event.target.closest("a[href^='#']")
    const href = link?.getAttribute("href")
    if (!link || href.length < 2 || link.classList.contains("overlay-lnk")) return
    const target = document.getElementById(decodeURIComponent(href.slice(1)))
    if (target && this.element.contains(target)) return

    event.stopPropagation()
    this.hide({ focus: false })
    if (target) focus(target)
  }

  // For bars that let focus leave them (outside-off): scroll the page so
  // the focused element isn't hidden behind the bar.
  keepFocusVisible() {
    if (!this.isOpen || this.closesOnOutsideActivity) return
    const active = document.activeElement
    if (!active || active === document.body || this.element.contains(active)) return

    const bar = this.element.getBoundingClientRect()
    const focused = active.getBoundingClientRect()
    if (this.element.classList.contains("wb-bar-t") && focused.top < bar.bottom) {
      window.scrollBy(0, bar.bottom - focused.top)
    } else if (this.element.classList.contains("wb-bar-b") && focused.bottom > bar.top) {
      window.scrollBy(0, focused.bottom - bar.top)
    }
  }
}
