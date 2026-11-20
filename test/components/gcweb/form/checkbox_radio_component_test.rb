require "test_helper"

module Gcweb
  module Form
    class CheckboxRadioComponentTest < ComponentTestCase
      PETS = [ %w[Dog dog], %w[Cat cat] ].freeze

      test "radios render GCWeb's gc-chckbxrdio fieldset" do
        render_inline(RadiosComponent.new(name: "pet", label: "Favourite pet", choices: PETS, value: "cat"))

        assert_selector "fieldset.gc-chckbxrdio > legend > span.field-name", text: "Favourite pet"
        assert_selector "fieldset > ul.list-unstyled.lst-spcd-2 > li.radio", count: 2
        assert_selector "li.radio > input[type='radio']#pet_dog[name='pet'][value='dog']:not([checked]) + label[for='pet_dog']", text: "Dog"
        assert_selector "input#pet_cat[checked]"
      end

      test "the legend is the fieldset's first child, before the hidden input" do
        render_inline(RadiosComponent.new(name: "pet", label: "Pet", choices: PETS))

        assert_selector "fieldset > legend:first-child"
        assert_selector "fieldset > legend + input[type='hidden'][name='pet'][value='']", visible: :hidden
      end

      test "include_hidden: false leaves out the hidden input" do
        render_inline(RadiosComponent.new(name: "pet", label: "Pet", choices: PETS, include_hidden: false))

        assert_no_selector "input[type='hidden']", visible: :all
      end

      test "a required radio group marks the legend and every radio" do
        render_inline(RadiosComponent.new(name: "pet", label: "Pet", choices: PETS, required: true))

        assert_selector "legend.required > strong.required[aria-hidden='true']", text: "(required)"
        assert_selector "input[type='radio'][required]", count: 2
      end

      test "a group's error goes in the legend and marks each input" do
        render_inline(RadiosComponent.new(name: "pet", label: "Pet", choices: PETS, required: true, error: "This field is required.", error_number: 2))

        assert_selector "legend.required > strong#pet-error.error > span.label.label-danger", text: "Error\u00A02: This field is required."
        assert_selector "input.error[aria-invalid='true']", count: 2
      end

      test "inline renders GCWeb's form-inline variant" do
        render_inline(RadiosComponent.new(name: "n", label: "Pick", choices: [ 1, 2 ], inline: true))

        assert_selector "fieldset.gc-chckbxrdio.form-inline > div.radio.label-inline > input#n_1 + label", text: "1"
        assert_no_selector "ul"
      end

      test "choices accept plain values, hashes and per-option attributes" do
        render_inline(RadiosComponent.new(name: "x", label: "X", choices: { "Yes, please" => "yes", "No" => "no" }))
        assert_selector "input#x_yes[value='yes'] + label", text: "Yes, please"

        render_inline(RadiosComponent.new(name: "x", label: "X", choices: [ "Two words", [ "B", "b", { data: { foo: "bar" } } ] ]))
        assert_selector "input#x_two_words[value='Two words']"
        assert_selector "input#x_b[data-foo='bar']"
      end

      test "disabled: takes the values to disable" do
        render_inline(RadiosComponent.new(name: "pet", label: "Pet", choices: PETS, disabled: [ "cat" ]))

        assert_selector "input#pet_cat[disabled]"
        assert_no_selector "input#pet_dog[disabled]"
      end

      test "checkboxes use an array name and check every chosen value" do
        render_inline(CheckboxesComponent.new(name: "condiments", label: "Condiments", choices: %w[ketchup relish mustard], value: %w[relish mustard]))

        assert_selector "li.checkbox > input[type='checkbox'][name='condiments[]']", count: 3
        assert_selector "input[type='hidden'][name='condiments[]'][value='']", visible: :hidden
        assert_selector "input[type='checkbox'][checked]", count: 2
        assert_no_selector "input#condiments_ketchup[checked]"
      end

      test "a required checkbox group has no required attribute and announces the marker" do
        render_inline(CheckboxesComponent.new(name: "c", label: "C", choices: %w[a b], required: true))

        assert_selector "legend.required > strong.required:not([aria-hidden])", text: "(required)"
        assert_no_selector "input[required]"
      end

      test "a checkbox group does not double the array suffix" do
        render_inline(CheckboxesComponent.new(name: "survey[condiments][]", label: "C", choices: %w[a]))

        assert_selector "input#survey_condiments_a[name='survey[condiments][]']"
      end

      test "a single checkbox renders GCWeb's tickbox with Rails' hidden input" do
        render_inline(CheckboxComponent.new(name: "remember_me", label: "Remember me"))

        assert_selector "div.checkbox.gc-chckbxrdio > input[type='hidden'][name='remember_me'][value='0']", visible: :hidden
        assert_selector "div.checkbox.gc-chckbxrdio > input[type='checkbox']#remember_me[value='1']:not([checked]) + label[for='remember_me'] > span.field-name", text: "Remember me"
        assert_no_selector ".form-control"
      end

      test "a single checkbox is ticked by its checked value or true" do
        render_inline(CheckboxComponent.new(name: "a", label: "A", value: "1"))
        assert_selector "input#a[checked]"

        render_inline(CheckboxComponent.new(name: "a", label: "A", value: true))
        assert_selector "input#a[checked]"

        render_inline(CheckboxComponent.new(name: "a", label: "A", value: "yes", checked_value: "yes", unchecked_value: "no"))
        assert_selector "input#a[value='yes'][checked]"
        assert_selector "input[type='hidden'][value='no']", visible: :hidden

        render_inline(CheckboxComponent.new(name: "a", label: "A", value: "0"))
        assert_no_selector "input#a[checked]"
      end

      test "a required single checkbox with an error, as wb-frmvld renders it" do
        render_inline(CheckboxComponent.new(name: "terms", label: "I agree", required: true, error: "This field is required.", error_number: 1))

        assert_selector "div.checkbox.gc-chckbxrdio.required:not(.has-error)"
        assert_selector "input#terms.error[required][aria-invalid='true']"
        assert_selector "label[for='terms']:not(.required) > strong.required[aria-hidden='true']"
        assert_selector "label[for='terms'] > strong#terms-error.error .label-danger", text: "Error\u00A01: This field is required."
      end
    end
  end
end
