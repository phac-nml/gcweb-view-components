require "test_helper"

module Gcweb
  class FormBuilderTest < ComponentTestCase
    def render_form(model, &fields)
      render_in_view_context(model, fields) do |m, f_block|
        gcweb_form_with(model: m, scope: :contact_information, url: "#") { |f| f_block.call(f) }
      end
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
