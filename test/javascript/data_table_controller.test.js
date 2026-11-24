// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"

let application
let submitted

const content = ({ q = "", pages = true, next = true, info = "Showing 1 to 10 of 57 entries" } = {}) => `
  <div class="dataTables_wrapper">
    <div class="dataTables_filter"><form action="/s" data-turbo-frame="f">
      <input type="search" name="q" value="${q}"><input type="hidden" name="sort" value="name"></form></div>
    <div class="dataTables_info">${info}</div>
    <div class="dataTables_length"><form action="/s" data-turbo-frame="f">
      <select name="limit"><option>10</option><option>25</option></select><button>Apply</button></form></div>
    <table class="dataTable"><thead><tr><th><a href="/s?sort=name&page=2" data-turbo-frame="f">Name</a></th>
      <th><a href="/s?sort=date" data-turbo-frame="f">Date</a></th></tr></thead>
      <tbody><tr><td><a class="row" href="/rows/1">Row</a></td></tr></tbody></table>
    ${pages ? `<nav class="dataTables_paginate"><a href="/s?page=1" data-turbo-frame="f" aria-current="page">1</a>
      ${next ? `<a href="/s?page=2" data-turbo-frame="f" rel="next">Next</a>` : ""}</nav>` : ""}
  </div>`

const $ = (selector) => document.querySelector(selector)
const filter = () => $("input[type=search]")
const tick = () => vi.advanceTimersByTimeAsync(1)

const type = (text) => {
  filter().focus()
  filter().value = text
  filter().dispatchEvent(new Event("input", { bubbles: true }))
}

const swap = (options) => {
  const frame = $("#f")
  frame.dispatchEvent(new Event("turbo:before-frame-render", { bubbles: true }))
  frame.innerHTML = content(options)
  frame.dispatchEvent(new Event("turbo:frame-render", { bubbles: true }))
}

beforeEach(async () => {
  vi.useFakeTimers()
  vi.spyOn(customElements, "get").mockReturnValue(class {})
  submitted = []
  document.body.innerHTML = `
    <div data-controller="gcweb--data-table" data-gcweb--data-table-live-class="live" data-gcweb--data-table-page-param-value="page">
      <turbo-frame id="f" data-gcweb--data-table-target="frame">${content()}</turbo-frame>
      <div role="status" data-gcweb--data-table-target="status"></div>
    </div>`
  document.body.onsubmit = (event) => {
    event.preventDefault()
    submitted.push(new URLSearchParams(new FormData(event.target)).toString())
  }
  document.body.onclick = (event) => event.preventDefault()
  application = Application.start()
  registerGcwebControllers(application)
  await tick()
})

afterEach(async () => {
  document.body.innerHTML = ""
  document.body.onsubmit = document.body.onclick = null
  await tick()
  application.stop()
  vi.restoreAllMocks()
  vi.useRealTimers()
})

describe("gcweb--data-table", () => {
  it("filters once, after a pause in typing", () => {
    type("a")
    vi.advanceTimersByTime(200)
    type("al")
    vi.advanceTimersByTime(299)
    expect(submitted).toEqual([])
    vi.advanceTimersByTime(1)
    expect(submitted).toEqual(["q=al&sort=name"])
  })

  it("Enter filters at once, without a second request", () => {
    type("al")
    filter().form.requestSubmit()
    vi.advanceTimersByTime(1000)
    expect(submitted).toHaveLength(1)
  })

  it("waits for a composition to end", () => {
    filter().dispatchEvent(new InputEvent("input", { bubbles: true, isComposing: true }))
    vi.advanceTimersByTime(1000)
    expect(submitted).toEqual([])
    filter().dispatchEvent(new CompositionEvent("compositionend", { bubbles: true }))
    vi.advanceTimersByTime(300)
    expect(submitted).toHaveLength(1)
  })

  it("waits for a request in progress", () => {
    $("#f").setAttribute("busy", "")
    type("al")
    vi.advanceTimersByTime(900)
    expect(submitted).toEqual([])
    $("#f").removeAttribute("busy")
    vi.advanceTimersByTime(300)
    expect(submitted).toHaveLength(1)
  })

  it("applies the page size on selection, with unapplied filter text", () => {
    type("al")
    $("select").value = "25"
    $("select").dispatchEvent(new Event("change", { bubbles: true }))
    vi.advanceTimersByTime(1000)
    expect(submitted).toEqual(["limit=25&q=al"])
    expect($("[data-controller]").classList.contains("live")).toBe(true)
  })

  it("sort links take unapplied filter text; row links and applied text are left alone", () => {
    $("th a").click()
    expect($("th a").getAttribute("href")).toBe("/s?sort=name&page=2")
    type("al")
    $(".row").click()
    expect($(".row").getAttribute("href")).toBe("/rows/1")
    $("th a").click()
    expect($("th a").search).toBe("?sort=name&q=al")
    vi.advanceTimersByTime(1000)
    expect(submitted).toEqual([])
  })

  it("keeps the filter's focus, text and caret through a swap, and what was typed meanwhile", () => {
    type("alp")
    filter().setSelectionRange(1, 2)
    swap({ q: "al" })
    expect(document.activeElement).toBe(filter())
    expect(filter().value).toBe("alp")
    expect([filter().selectionStart, filter().selectionEnd]).toEqual([1, 2])
    vi.advanceTimersByTime(300)
    expect(submitted).toEqual(["q=alp&sort=name"])
  })

  it("shows the server's filter when nothing was typed", () => {
    swap({ q: "zeta" })
    expect(filter().value).toBe("zeta")
    expect(document.activeElement).toBe(document.body)
  })

  it("keeps focus on the heading and the page size", () => {
    $("th:nth-child(2) a").focus()
    swap()
    expect(document.activeElement).toBe($("th:nth-child(2) a"))
    $("select").focus()
    swap()
    expect(document.activeElement).toBe($("select"))
  })

  it("keeps focus on Next, then the current page, then the filter", () => {
    $("[rel=next]").focus()
    swap()
    expect(document.activeElement).toBe($("[rel=next]"))
    swap({ next: false })
    expect(document.activeElement).toBe($("[aria-current]"))
    swap({ pages: false })
    expect(document.activeElement).toBe(filter())
  })

  it("announces the new info line; ignores frames in the rows", () => {
    expect($("[role=status]").textContent).toBe("")
    $(".row").dispatchEvent(new Event("turbo:frame-render", { bubbles: true }))
    expect($("[role=status]").textContent).toBe("")
    swap({ info: "Showing 1 to 8 of 8 entries" })
    expect($("[role=status]").textContent).toBe("Showing 1 to 8 of 8 entries")
  })

  it("drops typed text and the busy state from a restored snapshot", async () => {
    type("al")
    $("#f").setAttribute("busy", "")
    $("#f").setAttribute("aria-busy", "true")
    const snapshot = $("[data-controller]").cloneNode(true)
    $("[data-controller]").replaceWith(snapshot)
    await tick()
    expect(filter().value).toBe("")
    expect($("#f").hasAttribute("aria-busy")).toBe(false)
    type("be")
    vi.advanceTimersByTime(300)
    expect(submitted).toEqual(["q=be&sort=name"])
  })

  it("keeps text typed before it first connects", async () => {
    const early = $("[data-controller]").cloneNode(true)
    early.classList.remove("live")
    early.querySelector("input[type=search]").value = "al"
    $("[data-controller]").replaceWith(early)
    await tick()
    expect(filter().value).toBe("al")
  })

  it("does nothing without Turbo", async () => {
    customElements.get.mockReturnValue(undefined)
    const html = $("[data-controller]").outerHTML.replace(/ class="live"/, "")
    document.body.innerHTML = ""
    await tick()
    document.body.innerHTML = html
    await tick()
    type("al")
    vi.advanceTimersByTime(1000)
    expect(submitted).toEqual([])
    expect($(".live")).toBeNull()
  })
})
