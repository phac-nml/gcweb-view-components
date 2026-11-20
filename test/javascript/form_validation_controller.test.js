// @vitest-environment jsdom
import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it } from "vitest"
import { registerGcwebControllers } from "../../app/assets/javascripts/gcweb_view_components/index.js"
import { format, idFor, messageFor } from "../../app/assets/javascripts/gcweb_view_components/controllers/form_validation_controller.js"

// What gcweb_form_with passes in English (config/locales/gcweb_view_components.en.yml).
const MESSAGES = {
  required: "This field is required.",
  email: "Please enter a valid email address.",
  url: "Please enter a valid URL.",
  number: "Please enter a valid number.",
  date: "Please enter a valid date.",
  minlength: "Please enter at least %{count} characters.",
  maxlength: "Please enter no more than %{count} characters.",
  min: "Please enter a value greater than or equal to %{count}.",
  max: "Please enter a value less than or equal to %{count}.",
  step: "Please enter a multiple of %{count}.",
  pattern: "Invalid format.",
  prefix: "Error %{number}: ",
  summaryOne: "The form could not be submitted because 1 error was found.",
  summaryOther: "The form could not be submitted because %{count} errors were found.",
  separator: " - "
}

// The markup the gem's components render (see the Ruby component tests).
const textGroup = (id, label, attrs = "", required = true) => `
  <div class="form-group">
    <label for="${id}"${required ? ' class="required"' : ""}><span class="field-name">${label}</span>${required ? ' <strong class="required" aria-hidden="true">(required)</strong>' : ""}</label>
    <input class="form-control" id="${id}" name="c[${id}]" ${required ? "required" : ""} ${attrs}>
  </div>`

const choices = (type, name, legend, values, required = true) => `
  <fieldset class="gc-chckbxrdio">
    <legend${required ? ' class="required"' : ""}><span class="field-name">${legend}</span>${required ? ' <strong class="required">(required)</strong>' : ""}</legend>
    <input type="hidden" name="${name}" value="">
    <ul class="list-unstyled lst-spcd-2">${values.map((v) => `
      <li class="${type}"><input type="${type}" id="${idFor(name)}_${v}" name="${name}" value="${v}"${type === "radio" && required ? " required" : ""}><label for="${idFor(name)}_${v}">${v}</label></li>`).join("")}
    </ul>
  </fieldset>`

let application
let submits
let recordSubmit

afterEach(() => {
  application?.stop()
  document.removeEventListener("submit", recordSubmit)
  document.body.innerHTML = ""
})

const tick = () => new Promise((resolve) => setTimeout(resolve, 0))

const mount = async (fields, { id = "", before = "" } = {}) => {
  document.body.innerHTML = `
    <form${id ? ` id="${id}"` : ""} action="#" data-controller="gcweb--form-validation"
          data-gcweb--form-validation-messages-value='${JSON.stringify(MESSAGES)}'>${before}${fields}</form>`
  submits = []
  // Runs after the controller's listener (the event bubbles to document):
  // note whether the submit went ahead, then stop jsdom navigating.
  recordSubmit = (event) => {
    submits.push(!event.defaultPrevented)
    event.preventDefault()
  }
  document.addEventListener("submit", recordSubmit)
  application = Application.start()
  registerGcwebControllers(application)
  await tick()
  return document.querySelector("form")
}

const submit = (form) => form.requestSubmit()
const type = (input, value) => {
  input.value = value
  input.dispatchEvent(new Event("input", { bubbles: true }))
}
const blur = (input) => input.dispatchEvent(new FocusEvent("focusout", { bubbles: true }))
const text = (selector) => document.querySelector(selector)?.textContent

describe("helpers", () => {
  it("derives ids like the Ruby components", () => {
    expect(idFor("contact[email]")).toBe("contact_email")
    expect(idFor("survey[condiments][]")).toBe("survey_condiments")
  })

  it("fills Rails-style placeholders", () => {
    expect(format("At least %{count} characters", { count: 4 })).toBe("At least 4 characters")
  })

  it("maps constraint failures to wet-boew's messages", () => {
    document.body.innerHTML = `<input id="a" type="email" value="nope"><input id="b" minlength="4" value="ab"><input id="c" type="number" min="5" value="2"><input id="d" pattern="[A-Z]" value="a">`
    const [a, b, c, d] = ["a", "b", "c", "d"].map((id) => document.getElementById(id))
    expect(messageFor(a, MESSAGES)).toBe("Please enter a valid email address.")
    expect(messageFor(c, MESSAGES)).toBe("Please enter a value greater than or equal to 5.")
    expect(messageFor(d, MESSAGES)).toBe("Invalid format.")
    // tooShort only applies after a user edit, so jsdom reports it valid.
    expect(messageFor(b, MESSAGES)).toBeNull()
  })
})

describe("gcweb--form-validation controller", () => {
  it("turns off the browser's own validation and adds wb-frmvld's live region", async () => {
    const form = await mount(textGroup("first_name", "First Name"))

    expect(form.noValidate).toBe(true)
    expect(form.querySelector(":scope > div.arialive.wb-inv[aria-live='polite'][aria-relevant='all']")).not.toBeNull()
  })

  it("stops an invalid submit and renders the server's error markup", async () => {
    const form = await mount(textGroup("first_name", "First Name") + textGroup("email", "Email", 'type="email" value="not-an-email"'))
    submit(form)

    expect(submits).toEqual([false])
    expect(text("label[for=first_name] > strong#first_name-error.error > span.label.label-danger > span.prefix")).toBe("Error 1: ")
    expect(text("#first_name-error")).toBe("Error 1: This field is required.")
    expect(text("#email-error")).toBe("Error 2: Please enter a valid email address.")
    expect(document.querySelector("#first_name.form-control.error[aria-invalid='true']")).not.toBeNull()
    expect(document.querySelector(".form-group.has-error #first_name")).not.toBeNull()
  })

  it("shows and focuses the error summary, first in the form", async () => {
    const form = await mount(textGroup("first_name", "First Name") + textGroup("email", "Email", 'type="email"'), { id: "contact" })
    submit(form)

    const summary = form.firstElementChild
    expect(summary.matches("section#errors-contact.alert.alert-danger[tabindex='-1']")).toBe(true)
    expect(document.activeElement).toBe(summary)
    expect(text("section > h2")).toBe("The form could not be submitted because 2 errors were found.")
    const links = [...summary.querySelectorAll("li > a")]
    expect(links.map((a) => a.getAttribute("href"))).toEqual(["#first_name", "#email"])
    expect(links[1].textContent).toBe("Error 2: Email - This field is required.")
  })

  it("lets a valid submit through and removes the summary", async () => {
    const form = await mount(textGroup("first_name", "First Name"))
    submit(form)
    type(form.querySelector("#first_name"), "Ada")
    submit(form)

    expect(submits).toEqual([false, true])
    expect(form.querySelector("section")).toBeNull()
    expect(form.querySelector("strong.error")).toBeNull()
  })

  it("after a submit, rechecks fields as they are edited and renumbers", async () => {
    const form = await mount(textGroup("first_name", "First Name") + textGroup("last_name", "Last Name"))
    submit(form)
    type(form.querySelector("#first_name"), "Ada")

    expect(form.querySelector("#first_name-error")).toBeNull()
    expect(form.querySelector("#first_name").hasAttribute("aria-invalid")).toBe(false)
    expect(form.querySelector(".form-group.has-error #first_name")).toBeNull()
    expect(text("#last_name-error")).toBe("Error 1: This field is required.")
    expect(text("section > h2")).toBe("The form could not be submitted because 1 error was found.")

    type(form.querySelector("#last_name"), "Lovelace")
    expect(form.querySelector("section")).toBeNull()
  })

  it("before a submit, checks a field with a value when it loses focus, without a summary", async () => {
    const form = await mount(textGroup("email", "Email", 'type="email"', false) + textGroup("first_name", "First Name"))
    const email = form.querySelector("#email")
    blur(form.querySelector("#first_name"))
    expect(form.querySelector("strong.error")).toBeNull()

    type(email, "nope")
    expect(form.querySelector("strong.error")).toBeNull()
    blur(email)

    expect(text("#email-error")).toBe("Error 1: Please enter a valid email address.")
    expect(form.querySelector("section")).toBeNull()
    expect(text(".arialive")).toContain("Please enter a valid email address.")
  })

  it("puts radio and checkbox group errors in the legend, linked to the first option", async () => {
    const form = await mount(
      choices("radio", "survey[pet]", "Which is your favorite pet?", ["dog", "cat"]) +
      choices("checkbox", "survey[condiments][]", "Choose your condiments:", ["ketchup", "relish"]) +
      choices("checkbox", "survey[extras][]", "Extras", ["fries"], false)
    )
    submit(form)

    expect(text("legend > strong#survey_pet-error")).toBe("Error 1: This field is required.")
    expect(text("legend > strong#survey_condiments-error")).toBe("Error 2: This field is required.")
    expect(form.querySelector("#survey_extras-error")).toBeNull()
    expect(form.querySelectorAll("input[type=radio].error[aria-invalid='true']")).toHaveLength(2)
    expect([...form.querySelectorAll("section a")].map((a) => a.getAttribute("href"))).toEqual(["#survey_pet_dog", "#survey_condiments_ketchup"])
    expect(text("section li:first-child a")).toBe("Error 1: Which is your favorite pet? - This field is required.")

    const relish = form.querySelector("#survey_condiments_relish")
    relish.checked = true
    relish.dispatchEvent(new Event("change", { bubbles: true }))
    expect(form.querySelector("#survey_condiments-error")).toBeNull()
    expect(text("section > h2")).toBe("The form could not be submitted because 1 error was found.")
  })

  it("puts a required tickbox's error in its label", async () => {
    const form = await mount(`
      <div class="checkbox gc-chckbxrdio required">
        <input name="terms" type="hidden" value="0">
        <input type="checkbox" id="terms" name="terms" value="1" required>
        <label for="terms"><span class="field-name">I agree</span> <strong class="required" aria-hidden="true">(required)</strong></label>
      </div>`)
    submit(form)

    expect(text("label[for=terms] > strong#terms-error")).toBe("Error 1: This field is required.")
    expect(form.querySelector("#terms.error[aria-invalid='true']")).not.toBeNull()
    expect(form.querySelector(".has-error")).toBeNull()
  })

  it("picks up server-rendered errors: fixing one updates the numbers and summary", async () => {
    const serverSummary = `
      <section id="errors-default" class="alert alert-danger" tabindex="-1">
        <h2>The form could not be submitted because 3 errors were found.</h2>
        <ul>
          <li><a href="#first_name"><span class="prefix">Error&nbsp;1: </span>First Name - This field is required.</a></li>
          <li><a href="#last_name"><span class="prefix">Error&nbsp;2: </span>Last Name - This field is required.</a></li>
          <li><a><span class="prefix">Error&nbsp;3: </span>Already submitted.</a></li>
        </ul>
      </section>`
    const withError = (id, label, n) => `
      <div class="form-group has-error">
        <label for="${id}" class="required"><span class="field-name">${label}</span> <strong class="required" aria-hidden="true">(required)</strong> <strong id="${id}-error" class="error"><span class="label label-danger"><span class="prefix">Error&nbsp;${n}: </span>This field is required.</span></strong></label>
        <input class="form-control error" id="${id}" name="c[${id}]" required aria-invalid="true">
      </div>`
    const form = await mount(withError("first_name", "First Name", 1) + withError("last_name", "Last Name", 2), { before: serverSummary })

    type(form.querySelector("#first_name"), "Ada")

    expect(form.querySelector("#first_name-error")).toBeNull()
    expect(text("#last_name-error")).toBe("Error 1: This field is required.")
    expect(text("section > h2")).toBe("The form could not be submitted because 2 errors were found.")
    expect([...form.querySelectorAll("section li")].map((li) => li.textContent)).toEqual([
      "Error 1: Last Name - This field is required.",
      "Error 2: Already submitted."
    ])
  })

  it("ignores disabled and read-only fields", async () => {
    const form = await mount(textGroup("a", "A", "disabled") + textGroup("b", "B", "readonly"))
    submit(form)

    expect(submits).toEqual([true])
  })
})
