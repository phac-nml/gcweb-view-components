# Demo model for the checkbox and radio previews, using the questions from
# GCWeb's checkboxes and radio buttons examples
# (components/gc-chckbxrdio/gc-chckbxrdio-en.html).
class PreferenceSurvey
  include ActiveModel::Model
  include ActiveModel::Attributes

  PETS = %w[dog cat rat].freeze
  CONDIMENTS = %w[ketchup relish mustard].freeze

  attribute :pet, :string
  attribute :condiments, default: -> { [] }
  attribute :terms, :boolean

  validates :pet, :condiments, presence: true
  validates :pet, inclusion: { in: PETS }, allow_blank: true
  validates :terms, acceptance: { allow_nil: false }

  # Checkbox groups send a leading "" (the hidden input), so drop blanks.
  def condiments=(values)
    super(Array(values).compact_blank)
  end

  # Submitted with nothing chosen.
  def self.with_errors
    new.tap(&:validate)
  end
end
