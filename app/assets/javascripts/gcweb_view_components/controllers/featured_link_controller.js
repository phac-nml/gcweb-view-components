import { Controller } from "@hotwired/stimulus"

// Port of GCWeb's gc-featured-link.js (no jQuery).
//
// Paints `data-bg-color` onto the featured link band and picks the first text
// colour that reaches a 4.5:1 contrast ratio: white, then dark grey, then
// black. Styles are set through the CSSOM (element.style), which a strict
// Content-Security-Policy allows, unlike inline style="" attributes.
//
//   <section class="gc-featured-link" data-controller="gcweb--featured-link"
//            data-bg-color="#005B61">…</section>

export const WHITE = "#FFFFFF"
export const DARK_GREY = "#333333"
export const BLACK = "#000000"
const HEX_COLOR = /^#[0-9a-f]{6}$/i

export function relativeLuminance(hex) {
  const channels = [1, 3, 5].map((i) => parseInt(hex.substr(i, 2), 16) / 255)
  const [r, g, b] = channels.map((c) => (c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)))
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

export function contrastRatio(hexA, hexB) {
  const a = relativeLuminance(hexA)
  const b = relativeLuminance(hexB)
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
}

// GCWeb compares the ratio rounded to 2 decimals (toFixed(2)).
const meetsAA = (fg, bg) => Number(contrastRatio(fg, bg).toFixed(2)) >= 4.5

export function textColorFor(bgColor) {
  if (meetsAA(WHITE, bgColor)) return WHITE
  if (meetsAA(DARK_GREY, bgColor)) return DARK_GREY
  return BLACK
}

export default class extends Controller {
  connect() {
    const bgColor = this.element.dataset.bgColor
    if (!bgColor || !HEX_COLOR.test(bgColor)) return

    const textColor = textColorFor(bgColor)
    this.element.style.backgroundColor = bgColor
    this.element.style.color = textColor
    this.element.querySelectorAll("p, a").forEach((el) => {
      el.style.color = textColor
    })
  }
}
