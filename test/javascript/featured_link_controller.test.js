// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"
import {
  BLACK,
  DARK_GREY,
  WHITE,
  contrastRatio,
  textColorFor
} from "../../app/assets/javascripts/gcweb_view_components/controllers/featured_link_controller.js"

describe("contrast helpers (ported from GCWeb gc-featured-link.js)", () => {
  it("computes WCAG contrast ratios", () => {
    expect(contrastRatio("#FFFFFF", "#000000")).toBeCloseTo(21, 5)
    expect(contrastRatio("#777777", "#777777")).toBeCloseTo(1, 5)
  })

  it("picks the same text colours GCWeb renders on its demo page", () => {
    expect(textColorFor("#005B61")).toBe(WHITE) // dark example
    expect(textColorFor("#99dade")).toBe(DARK_GREY) // light example
    expect(textColorFor("#8F8F8F")).toBe(BLACK) // medium example
  })
})

describe("gcweb--featured-link controller", () => {
  let application

  afterEach(() => {
    application?.stop()
    document.body.innerHTML = ""
  })

  const mount = async (bgColor) => {
    document.body.innerHTML = `
      <section class="gc-featured-link" data-controller="gcweb--featured-link" data-bg-color="${bgColor}">
        <div class="container">
          <h2 class="wb-inv">Spotlight on</h2>
          <p><a class="stretched-link" href="#">[Promotion title]</a></p>
        </div>
      </section>`
    application = Application.start()
    registerGcwebControllers(application)
    await new Promise((resolve) => setTimeout(resolve, 0))
    return document.querySelector("section")
  }

  it("paints the background and an accessible text colour on the section, p and a", async () => {
    const section = await mount("#99dade")

    expect(section.style.backgroundColor).toBe("rgb(153, 218, 222)")
    expect(section.style.color).toBe("rgb(51, 51, 51)")
    expect(section.querySelector("p").style.color).toBe("rgb(51, 51, 51)")
    expect(section.querySelector("a").style.color).toBe("rgb(51, 51, 51)")
  })

  it("ignores values that are not 6-digit hex colours", async () => {
    const section = await mount("red")

    expect(section.style.backgroundColor).toBe("")
  })
})
