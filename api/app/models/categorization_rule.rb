class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :rule_predicate, presence: true
  validates :priority, presence: true, numericality: { greater_than: 0 }
  validate :validate_rule_predicate

  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(:priority) }

  # Bulk operation methods
  def self.bulk_activate(rule_ids, user_id)
    where(id: rule_ids, user_id: user_id).update_all(active: true)
  end

  def self.bulk_deactivate(rule_ids, user_id)
    where(id: rule_ids, user_id: user_id).update_all(active: false)
  end

  def self.bulk_delete(rule_ids, user_id)
    where(id: rule_ids, user_id: user_id).destroy_all
  end

  def self.bulk_reorder(rule_orders, user_id)
    # rule_orders should be array of {id: rule_id, priority: new_priority}
    rule_orders.each do |order|
      where(id: order[:id], user_id: user_id).update_all(priority: order[:priority])
    end
  end

  after_save :invalidate_user_cache
  after_destroy :invalidate_user_cache

  def matches_transaction?(transaction)
    evaluate_predicate(rule_predicate, transaction)
  rescue => e
    Rails.logger.error "Error matching rule #{id}: #{e.message}"
    false
  end

  private

  def evaluate_predicate(predicate, transaction)
    case predicate["type"]
    when "STRING"
      evaluate_string_predicate(predicate, transaction)
    when "NUMBER"
      evaluate_number_predicate(predicate, transaction)
    when "DATE"
      evaluate_date_predicate(predicate, transaction)
    when "COMPOUND"
      evaluate_compound_predicate(predicate, transaction)
    else
      false
    end
  end

  def evaluate_string_predicate(predicate, transaction)
    column_value = get_column_value(transaction, predicate["column"])
    return false unless column_value.is_a?(String)

    case predicate["operator"]
    when "CONTAINS"
      column_value.downcase.include?(predicate["operand"].downcase)
    when "EQUALS"
      column_value.downcase == predicate["operand"].downcase
    when "MATCHES"
      column_value.match?(Regexp.new(predicate["operand"], Regexp::IGNORECASE))
    when "STARTS_WITH"
      column_value.downcase.start_with?(predicate["operand"].downcase)
    when "ENDS_WITH"
      column_value.downcase.end_with?(predicate["operand"].downcase)
    else
      false
    end
  end

  def evaluate_number_predicate(predicate, transaction)
    column_value = get_column_value(transaction, predicate["column"])
    return false unless column_value.is_a?(Numeric)

    case predicate["operator"]
    when "GREATER_THAN"
      column_value > predicate["operand"]
    when "LESS_THAN"
      column_value < predicate["operand"]
    when "GREATER_THAN_OR_EQUAL"
      column_value >= predicate["operand"]
    when "LESS_THAN_OR_EQUAL"
      column_value <= predicate["operand"]
    when "EQUALS"
      column_value == predicate["operand"]
    else
      false
    end
  end

  def evaluate_date_predicate(predicate, transaction)
    column_value = get_column_value(transaction, predicate["column"])
    return false unless column_value.is_a?(Date)

    case predicate["operator"]
    when "AFTER"
      column_value > Date.parse(predicate["operand"])
    when "BEFORE"
      column_value < Date.parse(predicate["operand"])
    when "ON"
      column_value == Date.parse(predicate["operand"])
    when "DAY_OF_WEEK"
      column_value.strftime("%A").downcase == predicate["operand"].downcase
    else
      false
    end
  end

  def evaluate_compound_predicate(predicate, transaction)
    case predicate["operator"]
    when "AND"
      predicate["predicates"].all? { |p| evaluate_predicate(p, transaction) }
    when "OR"
      predicate["predicates"].any? { |p| evaluate_predicate(p, transaction) }
    else
      false
    end
  end

  def get_column_value(transaction, column)
    case column
    when "description"
      transaction.description
    when "amount"
      transaction.amount
    when "date"
      transaction.date
    else
      nil
    end
  end

  def validate_rule_predicate
    return unless rule_predicate.present?

    unless valid_predicate_structure?(rule_predicate)
      errors.add(:rule_predicate, "has invalid structure")
    end
  end

  def valid_predicate_structure?(predicate)
    return false unless predicate.is_a?(Hash)
    return false unless predicate["type"].present?

    case predicate["type"]
    when "STRING", "NUMBER", "DATE"
      predicate["column"].present? && 
      predicate["operator"].present? && 
      predicate["operand"].present?
    when "COMPOUND"
      predicate["operator"].present? &&
      predicate["predicates"].is_a?(Array) &&
      predicate["predicates"].all? { |p| valid_predicate_structure?(p) }
    else
      false
    end
  end

  private

  def invalidate_user_cache
    CachingService.invalidate_user_cache(user_id, :rules)
  end
end
