# Demo model for the fieldset previews: the "Contact Address" section of
# GCWeb's complex structure form (common/form/complex-structure-form-en.html),
# and a date of birth entered as year, month and day but validated as one
# date, so its error belongs to the fieldset rather than to one field.
class PersonalDetails
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address, :string
  attribute :city, :string
  attribute :postal_code, :string
  attribute :birth_year, :string
  attribute :birth_month, :string
  attribute :birth_day, :string

  validates :date_of_birth, presence: true

  # nil until all three parts make a real date.
  def date_of_birth
    parts = [ birth_year, birth_month, birth_day ]
    return unless parts.all? { |part| part.to_s.match?(/\A\d+\z/) }

    Date.new(*parts.map(&:to_i))
  rescue Date::Error
    nil
  end

  # Submitted with the date left empty.
  def self.with_errors
    new.tap(&:validate)
  end
end
