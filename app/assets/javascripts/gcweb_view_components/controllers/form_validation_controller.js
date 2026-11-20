import { Controller } from "@hotwired/stimulus"

// Client-side form validation: a port of wet-boew's wb-frmvld (GCWeb
// v20.0.1) built on the browser's Constraint Validation API instead of
// jQuery Validation. It writes the same markup the gem's form components
// render on the server, so client and server errors look and read alike:
//
//   <label for="email" class="required">… <strong id="email-error" class="error">
//     <span class="label label-danger"><span class="prefix">Error&nbsp;1: </span>…</span></strong></label>
//   <input id="email" class="form-control error" aria-invalid="true" …>
//
// plus the error summary (section#errors-*) at the top of the form.
//
// gcweb_form_with adds it to every form, with the messages in the page's
// language:
//
//   <form data-controller="gcweb--form-validation"
//         data-gcweb--form-validation-messages-value="{…}">
//
// When it connects it sets novalidate, so the browser's own bubbles only
// give way once this controller is running.
//
// Timing follows jQuery Validation as wb-frmvld configures it: everything
// is checked on submit, and the summary is shown and focused. After that,
// a field is checked again when it loses focus (or before any submit, when
// it has a value), and a field in error as it is edited. The summary and
// the "Error N" numbers update as errors come and go.

const TEXT_TYPES_SKIPPED = new Set(["hidden", "submit", "button", "reset", "image", "checkbox", "radio"])

// Same id the gem's Ruby code derives from a field name:
// "user[email]" -> "user_email", "user[tags][]" -> "user_tags".
export function idFor(name) {
  return name.replace(/\[\]$/, "").replace(/\]\[|[^-a-zA-Z0-9:.]/g, "_").replace(/_$/, "")
}

// Rails-style %{name} placeholders, as in the gem's locale files.
export function format(template, values = {}) {
  return String(template).replace(/%\{(\w+)\}/g, (match, key) => (key in values ? values[key] : match))
}

// wet-boew's message for the first constraint a control fails, or null.
export function messageFor(control, messages) {
  const v = control.validity
  const type = control.type

  if (v.valueMissing) return messages.required
  if (v.badInput) return /^(date|datetime-local|month|week|time)$/.test(type) ? messages.date : messages.number
  if (v.typeMismatch) {
    if (type === "email") return messages.email
    if (type === "url") return messages.url
    return control.validationMessage
  }
  if (v.patternMismatch) return messages.pattern
  if (v.tooShort) return format(messages.minlength, { count: control.minLength })
  if (v.tooLong) return format(messages.maxlength, { count: control.maxLength })
  if (v.rangeUnderflow) return format(messages.min, { count: control.min })
  if (v.rangeOverflow) return format(messages.max, { count: control.max })
  if (v.stepMismatch) return format(messages.step, { count: control.step })
  if (v.customError) return control.validationMessage
  return null
}

const attr = (value) => String(value).replace(/["\\]/g, "\\$&")

export default class extends Controller {
  static values = {
    messages: Object,
    headingLevel: { type: Number, default: 2 }
  }

  connect() {
    this.element.noValidate = true
    this.submitted = new Set()
    this.summaryShown = Boolean(this.summaryElement)

    // Fields already showing a (server) error are checked again as they
    // are edited, like fields that have been submitted.
    for (const field of this.fields()) {
      if (this.errorOf(field)) this.submitted.add(field.key)
    }

    this.liveRegion = document.createElement("div")
    this.liveRegion.className = "arialive wb-inv"
    this.liveRegion.setAttribute("aria-live", "polite")
    this.liveRegion.setAttribute("aria-relevant", "all")
    this.element.append(this.liveRegion)

    this.onSubmit = this.submit.bind(this)
    this.onFocusout = (event) => this.revalidate(event, "focusout")
    this.onInput = (event) => this.revalidate(event, "input")
    this.onChange = (event) => this.revalidate(event, "change")
    this.element.addEventListener("submit", this.onSubmit)
    this.element.addEventListener("focusout", this.onFocusout)
    this.element.addEventListener("input", this.onInput)
    this.element.addEventListener("change", this.onChange)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.onSubmit)
    this.element.removeEventListener("focusout", this.onFocusout)
    this.element.removeEventListener("input", this.onInput)
    this.element.removeEventListener("change", this.onChange)
    this.liveRegion?.remove()
  }

  // Check every field. With errors, stop the submit, show them and focus
  // the summary; without, let the submit (and Turbo) go ahead.
  submit(event) {
    const fields = this.fields()
    this.clearAll()

    let invalid = false
    for (const field of fields) {
      this.submitted.add(field.key)
      const message = this.check(field)
      if (message) {
        this.showError(field, message)
        invalid = true
      }
    }

    if (!invalid) {
      this.summaryShown = false
      this.summaryElement?.remove()
      return
    }

    event.preventDefault()
    this.summaryShown = true
    this.sync()
    this.summaryElement.focus()
  }

  revalidate(event, kind) {
    const field = this.fieldFor(event.target)
    if (!field) return

    const known = this.submitted.has(field.key) || Boolean(this.errorOf(field))
    const checkable = field.kind !== "text"
    const shouldCheck =
      kind === "focusout" ? !checkable && (known || this.hasValue(field)) :
      kind === "input" ? !checkable && known :
      (checkable && known) || field.controls[0].tagName === "SELECT"
    if (!shouldCheck) return

    const before = this.errorOf(field)?.textContent ?? null
    const message = this.check(field)
    this.clearError(field)
    if (message) {
      this.showError(field, message)
      this.submitted.add(field.key)
    }
    this.sync()

    // As wb-frmvld does: when a field's error changes while focus is
    // elsewhere, announce its label (with the error) in the live region.
    const after = this.errorOf(field)?.textContent ?? null
    if (before !== after && field.container) {
      this.liveRegion.textContent = field.controls.includes(document.activeElement)
        ? ""
        : field.container.textContent.replace(/\s+/g, " ").trim()
    }
  }

  // --- Fields ---------------------------------------------------------------

  // One entry per thing that gets an error: a text-like control, a radio
  // group, a checkbox group (gc-chckbxrdio fieldset) or a single checkbox.
  fields() {
    const fields = []
    const groups = new Map()

    for (const control of this.element.elements) {
      if (control.disabled || !control.name) continue
      const type = control.type

      if (type === "radio" || (type === "checkbox" && control.name.endsWith("[]") && control.closest("fieldset"))) {
        const key = `${type}:${control.name}`
        if (groups.has(key)) {
          groups.get(key).controls.push(control)
          continue
        }
        const legend = control.closest("fieldset").querySelector(":scope > legend")
        const field = { key, kind: type === "radio" ? "radios" : "checkboxes", controls: [control], container: legend, idBase: idFor(control.name) }
        groups.set(key, field)
        fields.push(field)
      } else if (type === "checkbox") {
        fields.push({ key: `id:${control.id}`, kind: "checkbox", controls: [control], container: this.labelFor(control), idBase: control.id })
      } else if (!TEXT_TYPES_SKIPPED.has(type) && control.willValidate) {
        fields.push({ key: `id:${control.id || control.name}`, kind: "text", controls: [control], container: this.labelFor(control), idBase: control.id || idFor(control.name) })
      }
    }
    return fields
  }

  fieldFor(control) {
    if (!control?.name) return null
    return this.fields().find((field) => field.controls.includes(control)) ?? null
  }

  labelFor(control) {
    return control.id ? this.element.querySelector(`label[for="${attr(control.id)}"]`) : control.closest("label")
  }

  hasValue(field) {
    return field.controls.some((control) => control.value !== "")
  }

  check(field) {
    const messages = this.messagesValue
    switch (field.kind) {
      case "radios":
        return field.controls.some((radio) => radio.validity.valueMissing) ? messages.required : null
      case "checkboxes": {
        // Checkbox groups carry no required attribute (it would mean "tick
        // this box"); a required group has legend.required.
        const required = field.container?.classList.contains("required")
        return required && !field.controls.some((box) => box.checked) ? messages.required : null
      }
      default:
        return messageFor(field.controls[0], messages)
    }
  }

  // --- Markup ---------------------------------------------------------------

  errorOf(field) {
    return field.container?.querySelector(":scope strong.error") ?? null
  }

  errorIdFor(field) {
    return `${field.idBase}-error`
  }

  showError(field, message) {
    for (const control of field.controls) {
      control.classList.add("error")
      control.setAttribute("aria-invalid", "true")
    }
    if (field.kind === "text") field.controls[0].closest(".form-group")?.classList.add("has-error")
    if (!field.container) return

    const strong = document.createElement("strong")
    strong.id = this.errorIdFor(field)
    strong.className = "error"
    const label = document.createElement("span")
    label.className = "label label-danger"
    const prefix = document.createElement("span")
    prefix.className = "prefix"
    label.append(prefix, message)
    strong.append(label)
    field.container.append(" ", strong)
  }

  clearError(field) {
    for (const control of field.controls) {
      control.classList.remove("error")
      control.removeAttribute("aria-invalid")
    }
    if (field.kind === "text") field.controls[0].closest(".form-group")?.classList.remove("has-error")
    const strong = this.errorOf(field)
    if (strong) this.removeError(strong)
  }

  // Remove every error in the form, server-rendered ones included.
  clearAll() {
    for (const field of this.fields()) this.clearError(field)
    this.element.querySelectorAll("label strong.error, legend strong.error").forEach((strong) => this.removeError(strong))
    this.element.querySelectorAll(".has-error").forEach((group) => group.classList.remove("has-error"))
  }

  removeError(strong) {
    const before = strong.previousSibling
    if (before?.nodeType === Node.TEXT_NODE && before.textContent.trim() === "") before.remove()
    strong.remove()
  }

  // Number the errors in page order and rebuild the summary from them.
  sync() {
    const strongs = [...this.element.querySelectorAll("label strong.error, legend strong.error")]
    const unlinked = this.unlinkedSummaryErrors()
    const entries = []

    strongs.forEach((strong, i) => {
      const number = i + 1
      const prefix = strong.querySelector(".prefix")
      const message = this.messageText(strong)
      if (prefix) prefix.textContent = format(this.messagesValue.prefix, { number })
      const container = strong.parentElement
      entries.push({ number, target: this.targetFor(container), label: this.fieldName(container), message })
    })
    unlinked.forEach((message, i) => entries.push({ number: strongs.length + i + 1, target: null, label: null, message }))

    if (!this.summaryShown) return
    if (entries.length === 0) {
      this.summaryElement?.remove()
      this.summaryShown = false
      return
    }
    this.renderSummary(entries)
  }

  messageText(strong) {
    const danger = strong.querySelector(".label-danger") ?? strong
    const prefix = danger.querySelector(".prefix")?.textContent ?? ""
    return danger.textContent.slice(prefix.length).trim()
  }

  fieldName(container) {
    const name = container.querySelector(".field-name")
    return (name ?? container).textContent.replace(/\s+/g, " ").trim()
  }

  // Where a summary link goes: the labelled control, a group's first
  // option, or a plain fieldset's legend (as wb-frmvld does).
  targetFor(container) {
    if (container.tagName === "LABEL") return container.htmlFor || null
    const fieldset = container.closest("fieldset")
    const option = fieldset?.classList.contains("gc-chckbxrdio") && fieldset.querySelector("input[type=radio], input[type=checkbox]")
    return option?.id || container.id || null
  }

  // Errors listed without a link (no field on the page), kept from a
  // server-rendered summary until the next submit.
  unlinkedSummaryErrors() {
    const summary = this.summaryElement
    if (!summary) return []
    return [...summary.querySelectorAll("li > a:not([href])")].map((link) => {
      const prefix = link.querySelector(".prefix")?.textContent ?? ""
      return link.textContent.slice(prefix.length).trim()
    })
  }

  get summaryElement() {
    return this.element.querySelector(":scope > section.alert[id^='errors-']")
  }

  renderSummary(entries) {
    const messages = this.messagesValue
    let summary = this.summaryElement
    if (!summary) {
      summary = document.createElement("section")
      summary.id = `errors-${this.element.id || "default"}`
      summary.className = "alert alert-danger"
      summary.tabIndex = -1
      this.element.prepend(summary)
    }

    const heading = document.createElement(`h${this.headingLevelValue}`)
    heading.textContent = format(entries.length === 1 ? messages.summaryOne : messages.summaryOther, { count: entries.length })
    const list = document.createElement("ul")
    for (const entry of entries) {
      const link = document.createElement("a")
      if (entry.target) link.href = `#${entry.target}`
      const prefix = document.createElement("span")
      prefix.className = "prefix"
      prefix.textContent = format(messages.prefix, { number: entry.number })
      link.append(prefix, [entry.label, entry.message].filter(Boolean).join(messages.separator))
      const item = document.createElement("li")
      item.append(link)
      list.append(item)
    }
    summary.replaceChildren(heading, list)
  }
}
