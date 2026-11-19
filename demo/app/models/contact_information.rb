# Demo model for the form previews: the "Contact Information" section of
# GCWeb's complex structure form (common/form/complex-structure-form-en.html).
class ContactInformation
  include ActiveModel::Model
  include ActiveModel::Attributes

  LANGUAGES = %w[English French].freeze

  attribute :rank, :string
  attribute :title, :string
  attribute :post_nominals, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :preferred_language, :string
  attribute :email, :string

  validates :first_name, :last_name, :preferred_language, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :preferred_language, inclusion: { in: LANGUAGES }, allow_blank: true

  # What GCWeb's demo shows after submitting: every required field empty and
  # an invalid email address.
  def self.with_errors
    new(email: "not-an-email").tap(&:validate)
  end
end
