require "test_helper"

module Gcweb
  module Form
    class TextFieldComponentTest < ComponentTestCase
      test "renders GCWeb's form-group markup for an optional field" do
        render_inline(TextFieldComponent.new(name: "rank", label: "Rank", size: 50))

        assert_selector "div.form-group:not(.has-error) > label[for='rank']:not(.required) > span.field-name", text: "Rank"
        assert_selector "div.form-group > input.form-control#rank[type='text'][name='rank'][size='50']"
        assert_no_selector "input[required]"
        assert_no_selector "strong.required"
      end

      test "marks required fields like GCWeb" do
        render_inline(TextFieldComponent.new(name: "first_name", label: "First Name", required: true))

        assert_selector "label.required > strong.required[aria-hidden='true']", text: "(required)"
        assert_selector "input#first_name[required]"
      end

      test "uses the French required text" do
        I18n.with_locale(:fr) { render_inline(TextFieldComponent.new(name: "x", label: "Prénom", required: true)) }

        assert_selector "strong.required", text: "(obligatoire)"
      end

      test "puts the hint inside the label after the field name" do
        render_inline(TextFieldComponent.new(name: "email", label: "Email", hint: "(yourname@domain.com)"))

        label = page.find("label[for='email']")
        assert_equal "Email (yourname@domain.com)", label.text.squish
      end

      test "renders wb-frmvld error markup" do
        render_inline(TextFieldComponent.new(name: "email", label: "Email", type: :email, required: true,
                                             error: "Please enter a valid email address.", error_number: 6))

        assert_selector "div.form-group.has-error"
        assert_selector "label > strong#email-error.error > span.label.label-danger > span.prefix", text: "Error 6: "
        assert_selector "span.label-danger", text: "Please enter a valid email address."
        assert_selector "input.form-control.error[aria-invalid='true'][type='email']"
      end

      test "numbers French errors with French spacing" do
        I18n.with_locale(:fr) { render_inline(TextFieldComponent.new(name: "x", label: "X", error: "Ce champ est obligatoire.", error_number: 1)) }

        assert_selector "span.prefix", text: "Erreur 1 : "
      end

      test "shows only the first of several errors and omits the number when not given" do
        render_inline(TextFieldComponent.new(name: "x", label: "X", error: [ "First.", "Second." ]))

        assert_selector "span.label-danger", text: "Error: First."
        assert_no_text "Second."
      end

      test "derives the id from the name like Rails" do
        render_inline(TextFieldComponent.new(name: "user[email]", label: "Email"))

        assert_selector "label[for='user_email']"
        assert_selector "input#user_email[name='user[email]']"
      end

      test "never renders a password value" do
        render_inline(TextFieldComponent.new(name: "password", label: "Password", type: :password, value: "secret"))

        assert_selector "input[type='password']"
        assert_no_selector "input[value]"
      end

      test "merges extra classes, data and aria attributes" do
        render_inline(TextFieldComponent.new(name: "x", label: "X", class: "input-lg", data: { testid: "x" },
                                             aria: { describedby: "x-note" }, error: "Bad", group_html: { class: "mrgn-bttm-lg" }))

        assert_selector "div.form-group.has-error.mrgn-bttm-lg"
        assert_selector "input.form-control.error.input-lg[data-testid='x'][aria-describedby='x-note'][aria-invalid='true']"
      end

      test "rejects unsupported input types" do
        assert_raises(ArgumentError) { TextFieldComponent.new(name: "x", label: "X", type: :checkbox) }
      end
    end
  end
end
