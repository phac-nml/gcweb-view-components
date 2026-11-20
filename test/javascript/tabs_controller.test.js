// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"
import { SMALL_VIEW } from "../../app/assets/javascripts/gcweb_view_components/controllers/tabs_controller.js"

// jsdom has no matchMedia: a stand-in whose answer the tests can change.
let small
let mediaListeners
const setSmallView = (value) => {
  small = value
  mediaListeners.forEach((listener) => listener({ matches: value }))
}

beforeEach(() => {
  small = false
  mediaListeners = []
  window.matchMedia = (query) => ({
    media: query,
    get matches() {
      return query === SMALL_VIEW && small
    },
    addEventListener: (_type, listener) => mediaListeners.push(listener),
    removeEventListener: (_type, listener) => {
      mediaListeners = mediaListeners.filter((candidate) => candidate !== listener)
    }
  })
  window.sessionStorage.clear()
  window.history.replaceState(null, "", "/tabs")
})

let application

afterEach(() => {
  application?.stop()
  document.body.innerHTML = ""
})

const tick = () => new Promise((resolve) => setTimeout(resolve, 0))

// What Gcweb::TabsComponent renders.
const panel = (id, title, body, open = false) => `
  <details id="${id}"${open ? " open" : ""}><summary>${title}</summary><div class="tgl-panel">${body}</div></details>`

const mount = async ({ classes = "", id = "tabs", after = "", panels } = {}) => {
  document.body.innerHTML = `
    <div class="wb-tabs ${classes}" id="${id}" data-controller="gcweb--tabs">
      <div class="tabpanels">${panels ?? [
        panel("p1", "Example 1", `<p>One <a href="#p3" id="inner">to three</a></p>`),
        panel("p2", "Example 2", "<p>Two</p>", true),
        panel("p3", "Example 3<br>(line 2)", "<p>Three</p>")
      ].join("")}</div>
    </div>${after}`
  application = Application.start()
  registerGcwebControllers(application)
  await tick()
  return document.querySelector(".wb-tabs")
}

const $ = (selector) => document.querySelector(selector)
const tab = (id) => $(`#${id}-lnk`)
const activeTab = () => $("[role=tablist] li.active a")?.id
const shownPanels = () => [...document.querySelectorAll(".tabpanels > details.in")].map((el) => el.id)
const key = (target, keyName, options = {}) =>
  target.dispatchEvent(new KeyboardEvent("keydown", { key: keyName, bubbles: true, cancelable: true, ...options }))
const click = (target) => target.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, button: 0 }))

describe("gcweb--tabs on a wide screen", () => {
  it("builds wb-tabs' tab list from the summaries", async () => {
    const tabs = await mount()

    expect(tabs.classList.contains("wb-tabs-inited")).toBe(true)
    expect(tabs.classList.contains("tabs-acc")).toBe(true)
    const list = tabs.firstElementChild
    expect(list.matches("ul.generated[role=tablist][aria-live=off][aria-hidden=false]")).toBe(true)
    const links = [...list.querySelectorAll("li[role=presentation] > a[role=tab]")]
    expect(links.map((a) => [a.id, a.getAttribute("href"), a.getAttribute("aria-controls")])).toEqual([
      ["p1-lnk", "#p1", "p1"],
      ["p2-lnk", "#p2", "p2"],
      ["p3-lnk", "#p3", "p3"]
    ])
    expect(links[2].innerHTML).toBe("Example 3<br>(line 2)")
  })

  it("shows the open panel and marks the rest as hidden tab panels", async () => {
    await mount()

    expect(activeTab()).toBe("p2-lnk")
    expect(tab("p2").getAttribute("aria-selected")).toBe("true")
    expect(tab("p2").tabIndex).toBe(0)
    expect(tab("p1").tabIndex).toBe(-1)
    const [p1, p2] = [$("#p1"), $("#p2")]
    expect(p2.matches("[role=tabpanel][open].fade.in[aria-hidden=false][aria-expanded=true][aria-labelledby=p2-lnk]")).toBe(true)
    expect(p1.matches("[role=tabpanel][open].fade.out.noheight[aria-hidden=true][aria-expanded=false]")).toBe(true)
    expect(p1.querySelector("summary").matches(".wb-toggle.tgl-tab[aria-hidden=true][tabindex='-1']")).toBe(true)
  })

  it("switches panels on click and remembers the choice for the session", async () => {
    const tabs = await mount()
    const changes = []
    tabs.addEventListener("gcweb--tabs:change", (event) => changes.push(event.detail.panel.id))
    click(tab("p3"))

    expect(activeTab()).toBe("p3-lnk")
    expect(shownPanels()).toEqual(["p3"])
    expect(window.sessionStorage.getItem("/tabs#tabs-activePanel")).toBe("p3")
    expect(changes).toEqual(["p3"])
  })

  it("opens the panel remembered from earlier in the session", async () => {
    window.sessionStorage.setItem("/tabs#tabs-activePanel", "p1")
    await mount()

    expect(shownPanels()).toEqual(["p1"])
  })

  it("ignore-session neither reads nor stores the choice", async () => {
    window.sessionStorage.setItem("/tabs#tabs-activePanel", "p1")
    await mount({ classes: "ignore-session" })
    expect(shownPanels()).toEqual(["p2"])

    click(tab("p3"))
    expect(window.sessionStorage.getItem("/tabs#tabs-activePanel")).toBe("p1")
  })

  it("opens the panel the URL hash names, or the one holding the hash's target", async () => {
    window.history.replaceState(null, "", "/tabs#p3")
    await mount()
    expect(shownPanels()).toEqual(["p3"])
    expect(window.sessionStorage.getItem("/tabs#tabs-activePanel")).toBe("p3")
    application.stop()

    window.history.replaceState(null, "", "/tabs#inner")
    await mount()
    expect(shownPanels()).toEqual(["p1"])
  })

  it("arrow keys move to the previous or next tab, wrapping around", async () => {
    await mount()
    tab("p2").focus()
    key(tab("p2"), "ArrowRight")
    expect(activeTab()).toBe("p3-lnk")
    expect(document.activeElement).toBe(tab("p3"))

    key(tab("p3"), "ArrowDown")
    expect(activeTab()).toBe("p1-lnk")

    key(tab("p1"), "ArrowLeft")
    expect(activeTab()).toBe("p3-lnk")

    key(tab("p3"), "ArrowUp")
    expect(activeTab()).toBe("p2-lnk")
    expect(document.activeElement).toBe(tab("p2"))
  })

  it("Enter moves focus into the panel and Ctrl+Up back to its tab", async () => {
    await mount()
    key(tab("p1"), "Enter")

    expect(shownPanels()).toEqual(["p1"])
    expect(document.activeElement).toBe($("#p1"))

    key($("#inner"), "ArrowUp", { ctrlKey: true })
    expect(document.activeElement).toBe(tab("p1"))
  })

  it("ignores keys with modifiers on a tab", async () => {
    await mount()
    key(tab("p2"), "ArrowRight", { altKey: true })

    expect(activeTab()).toBe("p2-lnk")
  })

  it("a link to another panel inside a panel opens it and focuses its tab", async () => {
    await mount()
    click(tab("p1"))
    click($("#inner"))

    expect(shownPanels()).toEqual(["p3"])
    expect(document.activeElement).toBe(tab("p3"))
  })

  it("a wb-tabs-ext link elsewhere on the page opens the panel it points to", async () => {
    await mount({ after: `<p><a href="#p3" class="wb-tabs-ext" id="ext">Show the third panel</a> <a href="#p1" id="plain" onclick="event.preventDefault()">plain</a></p>` })
    click($("#plain"))
    expect(shownPanels()).toEqual(["p2"])

    click($("#ext"))
    expect(shownPanels()).toEqual(["p3"])
    expect(document.activeElement).toBe(tab("p3"))
  })

  it("update-hash keeps the open panel's id in the URL", async () => {
    await mount({ classes: "update-hash" })
    expect(window.location.hash).toBe("#p2")

    click(tab("p1"))
    expect(window.location.hash).toBe("#p1")
  })

  it("wraps panel content that has no tgl-panel yet", async () => {
    await mount({ panels: `<details id="a"><summary>A</summary><p>Alpha</p></details><details id="b"><summary>B</summary><p>Beta</p></details>` })

    expect($("#a > summary + .tgl-panel > p").textContent).toBe("Alpha")
    expect(shownPanels()).toEqual(["a"])
  })

  it("rebuilds rather than duplicates the tab list when it reconnects", async () => {
    const tabs = await mount()
    application.stop()
    application = Application.start()
    registerGcwebControllers(application)
    await tick()

    expect(tabs.querySelectorAll(":scope > ul[role=tablist]")).toHaveLength(1)
  })
})

describe("gcweb--tabs on a small screen", () => {
  it("is an accordion of grouped details, without tab panel roles", async () => {
    small = true
    const tabs = await mount()

    expect(tabs.querySelector("[role=tablist]").getAttribute("aria-hidden")).toBe("true")
    const panels = [...tabs.querySelectorAll(".tabpanels > details")]
    expect(panels.map((p) => p.open)).toEqual([false, true, false])
    expect(panels.every((p) => p.getAttribute("name") === "tabs-grp" && !p.hasAttribute("role") && !p.classList.contains("fade"))).toBe(true)
    expect(panels[0].querySelector("summary").hasAttribute("aria-hidden")).toBe(false)
    expect(panels[0].querySelector("summary").hasAttribute("tabindex")).toBe(false)
  })

  it("switches between tabs and accordion as the screen changes, keeping the open panel", async () => {
    await mount()
    click(tab("p3"))
    setSmallView(true)

    expect([...document.querySelectorAll(".tabpanels > details[open]")].map((p) => p.id)).toEqual(["p3"])

    $("#p3").open = false
    $("#p1").open = true
    setSmallView(false)
    expect(shownPanels()).toEqual(["p1"])
    expect(activeTab()).toBe("p1-lnk")
  })

  it("opening a panel in the accordion remembers it", async () => {
    small = true
    await mount()
    $("#p1").open = true
    $("#p1").dispatchEvent(new Event("toggle"))

    expect(window.sessionStorage.getItem("/tabs#tabs-activePanel")).toBe("p1")
  })

  it("links open the panel and focus its summary", async () => {
    small = true
    await mount({ after: `<a href="#p3" class="wb-tabs-ext" id="ext">Show</a>` })
    click($("#ext"))

    expect($("#p3").open).toBe(true)
    expect(document.activeElement).toBe($("#p3 > summary"))
  })
})
