// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"

let application

// Emptying the page disconnects the controllers (Application#stop doesn't),
// so their document listeners go too.
afterEach(async () => {
  document.body.innerHTML = ""
  document.body.className = ""
  await tick()
  application?.stop()
  application = null
})

const tick = () => new Promise((resolve) => setTimeout(resolve, 0))

const mount = async (html) => {
  document.body.innerHTML = html
  application = Application.start()
  registerGcwebControllers(application)
  await tick()
}

const link = (id) => `<p><a href="#${id}" aria-controls="${id}" class="overlay-lnk" role="button" id="${id}-lnk">Open</a></p>`

// What Gcweb::OverlayComponent renders.
const overlay = (id, classes = "wb-panel-l", body = '<a href="#" id="first">First</a> <a href="#" id="last">Last</a>', extra = "") => `
  <section id="${id}" class="wb-overlay modal-content overlay-def ${classes}" aria-labelledby="${id}-title" data-controller="gcweb--overlay"${extra}>
    <header class="modal-header"><h2 class="modal-title" id="${id}-title">Title</h2></header>
    <div class="modal-body">${body}</div>
    <button type="button" class="mfp-close overlay-close" id="${id}-close">×</button>
  </section>`

const $ = (selector) => document.querySelector(selector)
const click = (element) => element.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
const key = (element, key, options = {}) => {
  const event = new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true, ...options })
  element.dispatchEvent(event)
  return event
}

describe("gcweb--overlay", () => {
  it("hides the overlay from assistive technology until it's opened", async () => {
    await mount(link("panel") + overlay("panel"))

    expect($("#panel").getAttribute("aria-hidden")).toBe("true")
    expect($("#panel").hasAttribute("role")).toBe(false)
  })

  it("a link to the overlay opens it as a dialog and focuses it", async () => {
    await mount(link("panel") + overlay("panel"))
    const event = new MouseEvent("click", { bubbles: true, cancelable: true })
    $("#panel-lnk").dispatchEvent(event)

    const panel = $("#panel")
    expect(event.defaultPrevented).toBe(true)
    expect(panel.classList.contains("open")).toBe(true)
    expect(panel.getAttribute("role")).toBe("dialog")
    expect(panel.getAttribute("aria-hidden")).toBe("false")
    expect(panel.getAttribute("aria-modal")).toBe("true")
    expect(document.activeElement).toBe(panel)
    expect(panel.getAttribute("tabindex")).toBe("-1")
  })

  it("Space on the link opens it too (it has role=button)", async () => {
    await mount(link("panel") + overlay("panel"))
    const event = key($("#panel-lnk"), " ")

    expect(event.defaultPrevented).toBe(true)
    expect($("#panel").classList.contains("open")).toBe(true)
  })

  it("the close button closes it and returns focus to the link", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))
    click($("#panel-close"))

    const panel = $("#panel")
    expect(panel.classList.contains("open")).toBe(false)
    expect(panel.classList.contains("user-closed")).toBe(true)
    expect(panel.getAttribute("aria-hidden")).toBe("true")
    expect(panel.hasAttribute("role")).toBe(false)
    expect(panel.hasAttribute("aria-modal")).toBe(false)
    expect(document.activeElement).toBe($("#panel-lnk"))
  })

  it("Escape closes it and returns focus to the link", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))
    key($("#first"), "Escape")

    expect($("#panel").classList.contains("open")).toBe(false)
    expect(document.activeElement).toBe($("#panel-lnk"))
  })

  it("Escape that something else handled doesn't close it", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))
    $("#first").addEventListener("keydown", (event) => event.preventDefault())
    key($("#first"), "Escape")

    expect($("#panel").classList.contains("open")).toBe(true)
  })

  it("Tab wraps around inside the overlay", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))

    let event = key($("#panel"), "Tab")
    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe($("#first"))

    event = key($("#first"), "Tab")
    expect(event.defaultPrevented).toBe(false) // the browser moves to the next one

    $("#panel-close").focus()
    event = key($("#panel-close"), "Tab")
    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe($("#first"))

    key($("#first"), "Tab", { shiftKey: true })
    expect(document.activeElement).toBe($("#panel-close"))
  })

  it("Tab skips hidden links", async () => {
    await mount(link("popup") + overlay("popup", "wb-popup-mid", '<p hidden><a href="#" id="hidden">Hidden</a></p><a href="#" id="first">First</a>'))
    click($("#popup-lnk"))
    key($("#popup"), "Tab")

    expect(document.activeElement).toBe($("#first"))
  })

  it("a click or focus outside closes it without moving focus", async () => {
    await mount(link("panel") + overlay("panel") + '<button id="outside">Outside</button>')
    click($("#panel-lnk"))
    await tick()
    $("#outside").focus()

    expect($("#panel").classList.contains("open")).toBe(false)
    expect($("#panel").classList.contains("user-closed")).toBe(false)
    expect(document.activeElement).toBe($("#outside"))

    click($("#panel-lnk"))
    await tick()
    click($("#outside"))
    expect($("#panel").classList.contains("open")).toBe(false)
  })

  it("clicks inside don't close it", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))
    await tick()
    click($("#panel .modal-title"))

    expect($("#panel").classList.contains("open")).toBe(true)
  })

  it("outside-off keeps it open on outside activity and lets Tab leave", async () => {
    await mount(link("bar") + overlay("bar", "wb-bar-t outside-off") + '<button id="outside">Outside</button>')
    click($("#bar-lnk"))
    await tick()
    $("#outside").focus()
    click($("#outside"))

    expect($("#bar").classList.contains("open")).toBe(true)
    expect($("#bar").hasAttribute("aria-modal")).toBe(false)

    $("#bar-close").focus()
    const event = key($("#bar-close"), "Tab")
    expect(event.defaultPrevented).toBe(false)
  })

  it("opening another overlay closes the first", async () => {
    await mount(link("one") + link("two") + overlay("one") + overlay("two", "wb-panel-r"))
    click($("#one-lnk"))
    await tick()
    click($("#two-lnk"))

    expect($("#one").classList.contains("open")).toBe(false)
    expect($("#two").classList.contains("open")).toBe(true)
  })

  it("a link inside to elsewhere on the page closes it and focuses the target", async () => {
    await mount(link("panel") + overlay("panel", "wb-panel-l", '<a href="#target" id="jump">Jump</a> <a href="#inside" id="stay">Stay</a><span id="inside"></span>') + '<h2 id="target">Target</h2>')
    click($("#panel-lnk"))
    click($("#stay"))
    expect($("#panel").classList.contains("open")).toBe(true)

    click($("#jump"))
    expect($("#panel").classList.contains("open")).toBe(false)
    expect(document.activeElement).toBe($("#target"))
  })

  it("middle and full-screen popups mark the body and keep the page title for printing", async () => {
    await mount("<h1>Page title</h1>" + link("popup") + overlay("popup", "wb-popup-mid"))
    click($("#popup-lnk"))

    expect(document.body.classList.contains("wb-overlay-dlg")).toBe(true)
    expect($("#popup").dataset.pgtitle).toBe("Page title")

    click($("#popup-close"))
    expect(document.body.classList.contains("wb-overlay-dlg")).toBe(false)
  })

  it("panels don't mark the body", async () => {
    await mount(link("panel") + overlay("panel"))
    click($("#panel-lnk"))

    expect(document.body.classList.contains("wb-overlay-dlg")).toBe(false)
  })

  it("opens on load without moving focus when the open value is set", async () => {
    await mount('<button id="before" autofocus>Before</button>' + overlay("popup", "wb-popup-mid", "", ' data-gcweb--overlay-open-value="true"'))
    $("#before").focus()
    await tick()

    expect($("#popup").classList.contains("open")).toBe(true)
    expect(document.activeElement).toBe($("#before"))
  })

  it("opens and closes on gcweb--overlay:open and :close events, and reports it", async () => {
    await mount(overlay("panel"))
    const events = []
    $("#panel").addEventListener("gcweb--overlay:opened", () => events.push("opened"))
    $("#panel").addEventListener("gcweb--overlay:closed", () => events.push("closed"))

    $("#panel").dispatchEvent(new CustomEvent("gcweb--overlay:open"))
    expect($("#panel").classList.contains("open")).toBe(true)
    expect(document.activeElement).toBe($("#panel"))

    $("#panel").dispatchEvent(new CustomEvent("gcweb--overlay:close", { detail: { noFocus: true } }))
    expect($("#panel").classList.contains("open")).toBe(false)
    expect(events).toEqual(["opened", "closed"])
  })

  it("a button that opens it from a click isn't counted as outside activity", async () => {
    await mount(overlay("panel") + '<button id="opener">Open</button>')
    $("#opener").addEventListener("click", () => $("#panel").dispatchEvent(new CustomEvent("gcweb--overlay:open")))
    click($("#opener"))

    expect($("#panel").classList.contains("open")).toBe(true)
  })

  it("stops listening when disconnected", async () => {
    await mount(link("panel") + overlay("panel"))
    $("#panel").removeAttribute("data-controller")
    await tick()
    click($("#panel-lnk"))

    expect($("#panel").classList.contains("open")).toBe(false)
  })
})
