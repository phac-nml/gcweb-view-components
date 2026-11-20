require "test_helper"

module Gcweb
  class FormBuilderTest < ComponentTestCase
    def render_form(model, &fields)
      render_in_view_context(model, fields) do |m, f_block|
        gcweb_form_with(model: m, scope: :contact_information, url: "#") { |f| f_block.call(f) }
      end
    end

    def render_survey(model, &fields)
      render_in_view_context(model, fields) do |m, f_block|
        gcweb_form_with(model: m, scope: :preference_survey, url: "#") { |f| f_block.call(f) }
      end
    end

    test "radio and checkbox groups take name, ids, value and required from the model" do
      render_survey(PreferenceSurvey.new(pet: "cat", condiments: %w[relish])) do |f|
        f.radio_buttons_group(:pet, PreferenceSurvey::PETS) + f.check_boxes_group(:condiments, PreferenceSurvey::CONDIMENTS)
      end

      assert_selector "legend.required > span.field-name", text: "Which is your favorite pet?"
      assert_selector "input[type='radio']#preference_survey_pet_cat[name='preference_survey[pet]'][required][checked]"
      assert_selector "input[type='checkbox']#preference_survey_condiments_relish[name='preference_survey[condiments][]'][checked]"
      assert_no_selector "input#preference_survey_condiments_ketchup[checked]"
    end

    test "check_box_group ticks from a boolean and is required by an acceptance validator" do
      render_survey(PreferenceSurvey.new(terms: true)) { |f| f.check_box_group(:terms) }

      assert_selector "input[type='hidden'][name='preference_survey[terms]'][value='0']", visible: :hidden
      assert_selector "input[type='checkbox']#preference_survey_terms[value='1'][required][checked]"
      assert_selector "div.checkbox.required > label[for='preference_survey_terms'] > span.field-name", text: "I agree to the terms and conditions"
    end

    test "radio and checkbox errors are numbered with the other fields" do
      render_survey(PreferenceSurvey.with_errors) do |f|
        f.radio_buttons_group(:pet, PreferenceSurvey::PETS) +
          f.check_boxes_group(:condiments, PreferenceSurvey::CONDIMENTS) +
          f.check_box_group(:terms)
      end

      assert_selector "legend #preference_survey_pet-error", text: "Error\u00A01: This field is required."
      assert_selector "legend #preference_survey_condiments-error", text: "Error\u00A02: This field is required."
      assert_selector "label #preference_survey_terms-error", text: "Error\u00A03: This field is required."
    end

    def render_details(model, &fields)
      render_in_view_context(model, fields) do |m, f_block|
        gcweb_form_with(model: m, scope: :personal_details, url: "#") { |f| f_block.call(f) }
      end
    end

    test "fieldset_group without an attribute is a section with a plain legend" do
      render_details(PersonalDetails.new) do |f|
        f.fieldset_group(legend: "Contact Address", heading: :h2) { f.text_field_group(:city) }
      end

      assert_selector "fieldset:not([class]) > legend:not([class]) > h2", exact_text: "Contact Address"
      assert_selector "fieldset > legend + .form-group > input#personal_details_city"
    end

    test "fieldset_group takes legend, required and a numbered error from the attribute" do
      render_details(PersonalDetails.with_errors) do |f|
        f.fieldset_group(:date_of_birth) { f.text_field_group(:birth_year) + f.text_field_group(:birth_month) } +
          f.text_field_group(:city, error: "Nope")
      end

      assert_selector "fieldset > legend.required > span.field-name", text: "Date of birth"
      assert_selector "legend > strong.required:not([aria-hidden])", text: "(required)"
      assert_selector "legend #personal_details_date_of_birth-error", text: "Error\u00A01: This field is required."
      assert_selector "fieldset input#personal_details_birth_year:not(.error):not([required])"
      assert_selector "#personal_details_city-error", text: "Error\u00A02: Nope"
    end

    test "fieldset_group legend: overrides the attribute's label" do
      render_details(PersonalDetails.new) { |f| f.fieldset_group(:date_of_birth, legend: "Born") { "" } }

      assert_selector "legend.required > span.field-name", exact_text: "Born"
    end

    test "gcweb_form_with puts an error summary first, matching the fields' numbers" do
      render_form(ContactInformation.with_errors) do |f|
        f.text_field_group(:rank) + f.text_field_group(:first_name) + f.text_field_group(:email, type: :email)
      end

      # 2 shown by the fields, then last name and language, which have none.
      assert_selector "form > section#errors-default:first-child h2", text: "because 4 errors were found."
      assert_selector "section li:nth-child(1) > a[href='#contact_information_first_name']", exact_text: "Error\u00A01: First Name - This field is required."
      assert_selector "section li:nth-child(2) > a[href='#contact_information_email']", text: "Error\u00A02: Email - Please enter"
      assert_selector "#contact_information_first_name-error", text: "Error\u00A01:"
    end

    test "errors the form didn't show are listed last without links" do
      model = ContactInformation.with_errors
      model.errors.add(:base, "Already submitted.")
      render_form(model) { |f| f.text_field_group(:first_name) }

      assert_selector "section li", count: 5
      assert_selector "section li:nth-child(2) > a:not([href])", exact_text: "Error\u00A02: Last Name - This field is required."
      assert_selector "section li:last-child > a:not([href])", exact_text: "Error\u00A05: Already submitted."
    end

    test "the summary links groups to their first option and fieldsets to their legend" do
      render_survey(PreferenceSurvey.with_errors) { |f| f.radio_buttons_group(:pet, PreferenceSurvey::PETS) + f.check_box_group(:terms) }
      assert_selector "section a[href='#preference_survey_pet_dog']", text: "Which is your favorite pet? - This field is required."
      assert_selector "section a[href='#preference_survey_terms']"

      render_details(PersonalDetails.with_errors) { |f| f.fieldset_group(:date_of_birth) { f.text_field_group(:birth_year) } }
      assert_selector "legend#personal_details_date_of_birth.required"
      assert_selector "section a[href='#personal_details_date_of_birth']", text: "Date of birth - This field is required."
    end

    test "the summary is named after the form and can be left out" do
      render_in_view_context { gcweb_form_with(model: ContactInformation.with_errors, scope: :contact_information, url: "#", id: "contact") { |f| f.text_field_group(:first_name) } }
      assert_selector "form#contact > section#errors-contact"

      render_in_view_context { gcweb_form_with(model: ContactInformation.with_errors, scope: :contact_information, url: "#", error_summary: false) { |f| f.text_field_group(:first_name) } }
      assert_no_selector "section"
      assert_selector "#contact_information_first_name-error"
    end

    test "gcweb_form_with adds the client-side validation controller with the locale's messages" do
      I18n.with_locale(:fr) { render_form(ContactInformation.new) { |f| f.text_field_group(:first_name) } }

      form = page.find("form[data-controller='gcweb--form-validation']")
      assert_equal "2", form["data-gcweb--form-validation-heading-level-value"]
      messages = JSON.parse(form["data-gcweb--form-validation-messages-value"])
      assert_equal "Ce champ est obligatoire.", messages["required"]
      assert_equal "Veuillez fournir au moins %{count} caractères.", messages["minlength"]
      assert_equal "Erreur\u00A0%{number}\u00A0: ", messages["prefix"]
      assert_equal "Le formulaire n'a pu être soumis car %{count} erreurs ont été trouvées.", messages["summaryOther"]
      assert_no_selector "form[novalidate]"
    end

    test "the controller joins the form's own controllers, and validate: false leaves it out" do
      render_in_view_context do
        gcweb_form_with(model: ContactInformation.new, scope: :contact_information, url: "#", data: { controller: "autosave" }, error_summary: { heading_level: 3 }) { "" }
      end
      assert_selector "form[data-controller='autosave gcweb--form-validation'][data-gcweb--form-validation-heading-level-value='3']"

      render_in_view_context { gcweb_form_with(model: ContactInformation.new, scope: :contact_information, url: "#", validate: false) { "" } }
      assert_no_selector "form[data-controller]"
    end

    test "no summary without errors" do
      render_form(ContactInformation.new) { |f| f.text_field_group(:first_name) }

      assert_no_selector "section"
    end

    test "gcweb_form_with uses Gcweb::FormBuilder" do
      builder = nil
      render_form(ContactInformation.new) { |f| builder = f; "" }

      assert_instance_of Gcweb::FormBuilder, builder
    end

    test "infers name, id, value and label from the model" do
      render_form(ContactInformation.new(rank: "Capt")) { |f| f.text_field_group(:rank, size: 50) }

      assert_selector "label[for='contact_information_rank'] > span.field-name", text: "Rank"
      assert_selector "input.form-control#contact_information_rank[name='contact_information[rank]'][value='Capt'][size='50']"
    end

    test "labels follow the locale" do
      I18n.with_locale(:fr) { render_form(ContactInformation.new) { |f| f.text_field_group(:first_name) } }

      assert_selector "span.field-name", text: "Prénom"
      assert_selector "strong.required", text: "(obligatoire)"
    end

    test "required comes from unconditional presence validators" do
      render_form(ContactInformation.new) do |f|
        f.text_field_group(:first_name) + f.text_field_group(:rank)
      end

      assert_selector "label[for='contact_information_first_name'].required"
      assert_selector "input#contact_information_first_name[required]"
      assert_selector "label[for='contact_information_rank']:not(.required)"
      assert_no_selector "input#contact_information_rank[required]"
    end

    test "explicit options win over what the builder infers" do
      render_form(ContactInformation.new) { |f| f.text_field_group(:rank, label: "Grade", required: true, id: "r") }

      assert_selector "label.required[for='r'] > span.field-name", text: "Grade"
      assert_selector "input#r[required]"
    end

    test "renders model errors numbered in render order" do
      render_form(ContactInformation.with_errors) do |f|
        f.text_field_group(:rank) + f.text_field_group(:first_name) + f.text_field_group(:email, type: :email)
      end

      assert_no_selector "label[for='contact_information_rank'] strong.error"
      assert_selector "#contact_information_first_name-error .label-danger", text: "Error 1: This field is required."
      assert_selector "#contact_information_email-error .label-danger", text: "Error 2: Please enter a valid email address."
      assert_selector "input#contact_information_email.error[aria-invalid='true'][value='not-an-email']"
    end

    test "never wraps fields in field_with_errors" do
      render_form(ContactInformation.with_errors) { |f| f.text_field_group(:first_name) }

      assert_no_selector ".field_with_errors"
    end

    test "text_area_group and select_group render their components" do
      render_form(ContactInformation.new(preferred_language: "French")) do |f|
        f.text_area_group(:post_nominals, rows: 4) +
          f.select_group(:preferred_language, ContactInformation::LANGUAGES, prompt: true)
      end

      assert_selector "textarea.form-control#contact_information_post_nominals[name='contact_information[post_nominals]'][rows='4']"
      assert_selector "select.form-control#contact_information_preferred_language[required] > option", count: 3
      assert_selector "option[value='French'][selected]"
    end

    test "standard Rails field methods are unchanged" do
      render_form(ContactInformation.new) { |f| f.text_field(:rank) }

      assert_selector "input#contact_information_rank[type='text']"
      assert_no_selector ".form-group"
      assert_no_selector "input.form-control"
    end
  end
end
