require "test_helper"

module Gcweb
  module Form
    class TextAreaAndSelectComponentTest < ComponentTestCase
      test "text area renders a form-control textarea with its value" do
        render_inline(TextAreaComponent.new(name: "post_nominals", label: "Post Nominals", rows: 4, cols: 51, value: "PhD"))

        assert_selector "div.form-group > label[for='post_nominals'] > span.field-name", text: "Post Nominals"
        assert_selector "textarea.form-control#post_nominals[name='post_nominals'][rows='4'][cols='51']", text: "PhD"
      end

      test "text area shows errors like other fields" do
        render_inline(TextAreaComponent.new(name: "message", label: "Message", required: true, error: "This field is required."))

        assert_selector "div.form-group.has-error > label.required > strong#message-error.error"
        assert_selector "textarea.form-control.error[required][aria-invalid='true']"
      end

      test "select renders choices with the current value selected" do
        render_inline(SelectComponent.new(name: "lang", label: "Language", choices: [ %w[English en], %w[French fr] ], value: "fr"))

        assert_selector "select.form-control#lang[name='lang'] > option", count: 2
        assert_selector "option[value='fr'][selected]", text: "French"
      end

      test "select prompt uses GCWeb's text per locale" do
        render_inline(SelectComponent.new(name: "lang", label: "Language", choices: %w[en fr], prompt: true))
        assert_selector "select > option:first-child[value='']", text: "Make your selection"

        I18n.with_locale(:fr) { render_inline(SelectComponent.new(name: "lang", label: "Langue", choices: %w[en fr], prompt: true)) }
        assert_selector "select > option:first-child[value='']", text: "Faites votre choix"
      end

      test "select accepts a custom prompt and prebuilt option HTML" do
        options = '<optgroup label="A"><option value="a">A</option></optgroup>'.html_safe
        render_inline(SelectComponent.new(name: "x", label: "X", choices: options, prompt: "Pick one"))

        assert_selector "option[value='']", text: "Pick one"
        assert_selector "optgroup[label='A'] > option[value='a']"
      end

      test "multiple select gets an array name" do
        render_inline(SelectComponent.new(name: "tags", label: "Tags", choices: %w[a b], multiple: true))

        assert_selector "select[multiple][name='tags[]']"
      end
    end
  end
end
