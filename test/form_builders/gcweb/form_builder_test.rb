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
