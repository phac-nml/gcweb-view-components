module Gcweb
  # @label Form builder
  #
  # `Gcweb::FormBuilder` renders GCWeb form groups from a model. It is
  # opt-in: use `gcweb_form_with` or `form_with(builder: Gcweb::FormBuilder)`.
  #
  # ```erb
  # <%= gcweb_form_with model: @contact, url: contacts_path do |f| %>
  #   <%= f.text_field_group :first_name %>
  #   <%= f.text_area_group :post_nominals, rows: 4 %>
  #   <%= f.select_group :preferred_language, choices, prompt: true %>
  #   <%= f.text_field_group :email, type: :email %>
  #   <%= f.radio_buttons_group :pet, pet_choices %>
  #   <%= f.check_boxes_group :condiments, condiment_choices %>
  #   <%= f.check_box_group :terms %>
  #   <%= f.fieldset_group :date_of_birth do %> … <% end %>
  # <% end %>
  # ```
  #
  # Forms also get the `gcweb--form-validation` Stimulus controller, which
  # checks fields in the browser first (pass `validate: false` to leave it
  # out). Register the gem's controllers to use it:
  #
  # ```js
  # import { registerGcwebControllers } from "gcweb_view_components"
  # registerGcwebControllers(application)
  # ```
  #
  # Labels come from `human_attribute_name`, the required marker from
  # presence (or acceptance) validators, and errors from `model.errors`, numbered like
  # wet-boew's "Error 1: …". When there are errors, `gcweb_form_with` puts
  # an error summary linking to each field at the top of the form.
  #
  # The example is the "Contact Information" section of GCWeb's
  # [complex structure form](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html).
  class FormBuilderPreview < ViewComponent::Preview
    # @label Contact information
    def contact_information
      render_with_template(template: "gcweb/form_builder_preview/contact_information", locals: { contact: ContactInformation.new })
    end

    # @label Contact information with errors
    #
    # The same form after a failed submit: the model's validation errors,
    # rendered server-side with the markup wet-boew's validation uses, and
    # the error summary (focused on load) at the top.
    def contact_information_with_errors
      render_with_template(template: "gcweb/form_builder_preview/contact_information", locals: { contact: ContactInformation.with_errors })
    end

    # @label Client-side validation
    #
    # The contact form with a submit button. Submit it empty, or with an
    # invalid email address: the `gcweb--form-validation` controller checks
    # the fields in the browser and shows the same errors and summary the
    # server renders, without a round trip. Fix a field and its error and
    # the summary update.
    def client_validation
      render_with_template(template: "gcweb/form_builder_preview/contact_information", locals: { contact: ContactInformation.new, submit: true })
    end

    # @label Checkboxes and radio buttons
    #
    # `radio_buttons_group`, `check_boxes_group` and `check_box_group`. The
    # questions are from GCWeb's
    # [checkboxes and radio buttons examples](https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-en.html).
    def preferences
      render_with_template(template: "gcweb/form_builder_preview/preferences", locals: { survey: PreferenceSurvey.new })
    end

    # @label Checkboxes and radio buttons with errors
    #
    # Submitted with nothing chosen. Each group's error is in its legend,
    # the tickbox's in its label.
    def preferences_with_errors
      render_with_template(template: "gcweb/form_builder_preview/preferences", locals: { survey: PreferenceSurvey.with_errors })
    end

    # @label Fieldsets
    #
    # `fieldset_group` without an attribute is a section of the form (the
    # "Contact Address" section of GCWeb's complex structure form). With
    # one, here a date of birth entered as three fields, the legend,
    # required marker and error come from the attribute.
    def personal_details
      render_with_template(template: "gcweb/form_builder_preview/personal_details", locals: { details: PersonalDetails.new })
    end

    # @label Fieldsets with errors
    #
    # Submitted with the date left empty: the error is on the date's legend,
    # not on one of its fields.
    def personal_details_with_errors
      render_with_template(template: "gcweb/form_builder_preview/personal_details", locals: { details: PersonalDetails.with_errors })
    end
  end
end
