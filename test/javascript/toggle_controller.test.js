// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"
import { parseOptions } from "../../app/assets/javascripts/gcweb_view_components/controllers/toggle_controller.js"

let application

beforeEach(() => {
  window.sessionStorage.clear()
  window.localStorage.clear()
})

// Emptying the page disconnects the controllers (Application#stop doesn't),
// so their window listeners go too.
afterEach(async () => {
  document.body.innerHTML = ""
  await tick()
  application?.stop()
  application = null
})

const tick = () => new Promise((resolve) => setTimeout(resolve, 0))

const start = async () => {
  application = Application.start()
  registerGcwebControllers(application)
  await tick()
}

const mount = async (html) => {
  document.body.innerHTML = html
  await start()
}

// Restarts the controllers on the same markup, like a page reload.
const reload = async () => {
  const html = document.body.innerHTML
  document.body.innerHTML = ""
  await tick()
  application.stop()
  document.body.innerHTML = html
  await start()
}

const toggleButton = (id, options) =>
  `<button type="button" id="${id}" class="btn wb-toggle" data-controller="gcweb--toggle" data-toggle='${JSON.stringify(options)}'>${id}</button>`

const details = (id, open = false, extra = "") =>
  `<details id="${id}"${open ? " open" : ""}${extra}><summary>${id}</summary><p>Example content.</p></details>`

const $ = (selector) => document.querySelector(selector)
const click = (element) => element.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
const openIds = () => [...document.querySelectorAll("details[open]")].map((element) => element.id)

describe("parseOptions", () => {
  it("merges GCWeb's data-toggle JSON with wet-boew's defaults", () => {
    expect(parseOptions('{"selector": ".box"}')).toEqual({ stateOn: "on", stateOff: "off", selector: ".box" })
    expect(parseOptions(undefined)).toEqual({ stateOn: "on", stateOff: "off" })
  })
})

describe("gcweb--toggle", () => {
  it("lists the elements it controls in aria-controls, giving them ids", async () => {
    await mount(`<div id="faq">${toggleButton("all", { selector: "details", parent: "#faq" })}${details("a")}<details><summary>B</summary></details></div>`)

    const controls = $("#all").getAttribute("aria-controls").split(" ")
    expect(controls[0]).toBe("a")
    expect(controls[1]).toMatch(/^gcweb-toggle-\d+$/)
    expect(document.getElementById(controls[1]).localName).toBe("details")
  })

  it("'Toggle' opens every details if any is closed, else closes them all", async () => {
    await mount(`<div id="faq">${toggleButton("toggle", { selector: "details", parent: "#faq" })}${details("a", true)}${details("b")}</div>`)
    click($("#toggle"))
    expect(openIds()).toEqual(["a", "b"])
    expect($("#a").classList.contains("on")).toBe(true)

    click($("#toggle"))
    expect(openIds()).toEqual([])
    expect($("#b").classList.contains("off")).toBe(true)
  })

  it("type on and off only open or only close", async () => {
    await mount(`<div id="faq">${toggleButton("on", { selector: "details", parent: "#faq", type: "on" })}${toggleButton("off", { selector: "details", parent: "#faq", type: "off" })}${details("a")}${details("b")}</div>`)
    click($("#on"))
    click($("#on"))
    expect(openIds()).toEqual(["a", "b"])

    click($("#off"))
    expect(openIds()).toEqual([])
  })

  it("only touches elements inside its parent", async () => {
    await mount(`<div id="faq">${toggleButton("on", { selector: "details", parent: "#faq", type: "on" })}${details("inside")}</div>${details("outside")}`)
    click($("#on"))

    expect(openIds()).toEqual(["inside"])
  })

  it("remembers each selector's state for the next toggle, and swaps the state classes", async () => {
    await mount(`${toggleButton("toggle", { selector: ".box" })}${toggleButton("on", { selector: ".box", type: "on" })}<span class="box" id="b1"></span><span class="box" id="b2"></span>`)
    click($("#toggle"))
    expect([...document.querySelectorAll(".box.on")]).toHaveLength(2)

    click($("#toggle"))
    expect([...document.querySelectorAll(".box.off")]).toHaveLength(2)

    click($("#on"))
    click($("#toggle"))
    expect([...document.querySelectorAll(".box.off")]).toHaveLength(2)
  })

  it("uses the stateOn and stateOff classes it's given", async () => {
    await mount(`${toggleButton("toggle", { selector: ".panel", stateOn: "shown", stateOff: "hidden" })}<span class="panel"></span>`)
    click($("#toggle"))
    expect($(".panel").className).toBe("panel shown")

    click($("#toggle"))
    expect($(".panel").className).toBe("panel hidden")
  })

  it("toggles itself without a selector", async () => {
    await mount(`<span id="self" class="wb-toggle" data-controller="gcweb--toggle" data-toggle="{}"></span>`)
    click($("#self"))
    expect($("#self").classList.contains("on")).toBe(true)
    expect($("#self").hasAttribute("aria-controls")).toBe(false)

    click($("#self"))
    expect($("#self").classList.contains("off")).toBe(true)
  })

  it("a summary toggles its own details", async () => {
    await mount(`<details id="d"><summary class="wb-toggle" data-controller="gcweb--toggle" data-toggle="{}">Example</summary><p>Content</p></details>`)
    click($("summary"))
    expect($("#d").open).toBe(true)
    expect(document.activeElement).toBe($("summary"))

    click($("summary"))
    expect($("#d").open).toBe(false)
  })

  it("a group keeps one element on", async () => {
    await mount(
      [1, 2, 3].map((n) => toggleButton(`b${n}`, { selector: `#t${n}`, group: ".grouped", type: "on" })).join("") +
      [1, 2, 3].map((n) => details(`t${n}`, false, ' class="grouped"')).join("")
    )
    click($("#b2"))
    expect(openIds()).toEqual(["t2"])

    click($("#b3"))
    expect(openIds()).toEqual(["t3"])
    expect($("#t2").classList.contains("off")).toBe(true)
  })

  it("as an accordion, a summary opens its section, closes the others, and can close itself", async () => {
    const section = (n, open = false) => `
      <details class="acc-group"${open ? " open" : ""} id="s${n}">
        <summary class="wb-toggle tgl-tab" data-controller="gcweb--toggle" data-toggle='{"parent": "#acc", "group": ".acc-group"}'>Example ${n}</summary>
        <div class="tgl-panel"><p>Content</p></div>
      </details>`
    await mount(`<div class="accordion" id="acc">${section(1, true)}${section(2)}${section(3)}</div>`)

    click($("#s3 > summary"))
    expect(openIds()).toEqual(["s3"])

    click($("#s3 > summary"))
    expect(openIds()).toEqual([])
    expect($("#acc").hasAttribute("role")).toBe(false)
  })

  it("dispatches gcweb--toggle:toggled", async () => {
    await mount(`${toggleButton("on", { selector: "details", type: "on" })}${details("a")}`)
    const events = []
    $("#on").addEventListener("gcweb--toggle:toggled", (event) => events.push([event.detail.isOn, event.detail.elements.map((e) => e.id)]))
    click($("#on"))

    expect(events).toEqual([[true, ["a"]]])
  })
})

describe("gcweb--toggle persistence and printing", () => {
  const persisted = (persist) => `
    <details id="d"><summary id="sum" class="wb-toggle" data-controller="gcweb--toggle" data-toggle='{"persist": "${persist}"}'>Example</summary><p>Content</p></details>`

  it("persist: session restores the state on the next page load", async () => {
    await mount(persisted("session"))
    click($("#sum"))
    expect(window.sessionStorage.getItem("wb-togglesum")).toBe("on")

    await reload()
    expect($("#d").open).toBe(true)

    click($("#sum"))
    await reload()
    expect($("#d").open).toBe(false)
  })

  it("persist: local uses localStorage", async () => {
    await mount(persisted("local"))
    click($("#sum"))

    expect(window.localStorage.getItem("wb-togglesum")).toBe("on")
    expect(window.sessionStorage.getItem("wb-togglesum")).toBeNull()
  })

  it("a grouped toggle forgets the group's other saved states", async () => {
    window.sessionStorage.setItem("wb-toggle.grouped" + "b1", "on")
    await mount(
      [1, 2].map((n) => toggleButton(`b${n}`, { selector: `#t${n}`, group: ".grouped", type: "on", persist: "session" })).join("") +
      [1, 2].map((n) => details(`t${n}`, false, ' class="grouped"')).join("")
    )
    click($("#b2"))

    expect(window.sessionStorage.getItem("wb-toggle.groupedb1")).toBeNull()
    expect(window.sessionStorage.getItem("wb-toggle.groupedb2")).toBe("on")
  })

  it("print sets the state before printing", async () => {
    await mount(`
      <details id="opens"><summary class="wb-toggle" data-controller="gcweb--toggle" data-toggle='{"print": "on"}'>A</summary></details>
      <details id="closes" open><summary class="wb-toggle" data-controller="gcweb--toggle" data-toggle='{"print": "off"}'>B</summary></details>`)
    window.dispatchEvent(new Event("beforeprint"))

    expect($("#opens").open).toBe(true)
    expect($("#closes").open).toBe(false)
  })

  it("stops listening for printing when disconnected", async () => {
    await mount(`<details id="opens"><summary class="wb-toggle" data-controller="gcweb--toggle" data-toggle='{"print": "on"}'>A</summary></details>`)
    $("summary").removeAttribute("data-controller")
    await tick()
    window.dispatchEvent(new Event("beforeprint"))

    expect($("#opens").open).toBe(false)
  })
})
