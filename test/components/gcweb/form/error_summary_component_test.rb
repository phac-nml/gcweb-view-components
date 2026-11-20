require "test_helper"

module Gcweb
  module Form
    class ErrorSummaryComponentTest < ComponentTestCase
      ERRORS = [
        { number: 1, target: "first_name", label: "First Name", message: "This field is required." },
        { number: 2, target: "email", label: "Email", message: "Please enter a valid email address." }
      ].freeze

      test "renders wb-frmvld's summary markup" do
        render_inline(ErrorSummaryComponent.new(errors: ERRORS))

        assert_selector "section#errors-default.alert.alert-danger[tabindex='-1'][autofocus]"
        assert_selector "section > h2:first-child", exact_text: "The form could not be submitted because 2 errors were found."
        assert_selector "section > h2 + ul > li", count: 2
        assert_selector "li > a[href='#first_name'] > span.prefix:first-child", exact_text: "Error 1: "
        assert_selector "li > a[href='#email']", exact_text: "Error 2: Email - Please enter a valid email address."
      end

      test "one error uses the singular heading, in each language" do
        render_inline(ErrorSummaryComponent.new(errors: ERRORS.first(1)))
        assert_selector "h2", exact_text: "The form could not be submitted because 1 error was found."

        I18n.with_locale(:fr) { render_inline(ErrorSummaryComponent.new(errors: ERRORS)) }
        assert_selector "h2", exact_text: "Le formulaire n'a pu être soumis car 2 erreurs ont été trouvées."
        assert_selector "a[href='#first_name']", exact_text: "Erreur 1 : First Name - This field is required."
      end

      test "an error without a target or label is listed without a link" do
        render_inline(ErrorSummaryComponent.new(errors: [ { number: 3, target: nil, label: nil, message: "Already submitted." } ]))

        assert_selector "li > a:not([href])", exact_text: "Error 3: Already submitted."
      end

      test "renders nothing without errors" do
        render_inline(ErrorSummaryComponent.new(errors: []))

        assert_no_selector "section"
      end

      test "id, heading level and autofocus can be changed" do
        render_inline(ErrorSummaryComponent.new(errors: ERRORS, id: "errors-signup", heading_level: 3, autofocus: false))

        assert_selector "section#errors-signup:not([autofocus]) > h3"
        assert_raises(ArgumentError) { ErrorSummaryComponent.new(errors: ERRORS, heading_level: 1) }
      end
    end
  end
end
