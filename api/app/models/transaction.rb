class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :anomalies, dependent: :destroy

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :date, presence: true

  scope :uncategorized, -> { where(category_id: nil) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  after_create :check_for_anomalies
  after_create :apply_categorization_rules, if: :should_apply_categorization_rules_on_create?
  after_update :apply_categorization_rules, if: :should_apply_categorization_rules_on_update?
  after_save :invalidate_user_cache, :broadcast_update, unless: :skip_callbacks
  after_destroy :invalidate_user_cache, :broadcast_destroy, unless: :skip_callbacks

  # Bulk operation methods
  def self.bulk_categorize(transaction_ids, category_id, user_id)
    CategorizationEngine.bulk_categorize(transaction_ids, category_id, user_id)
  end

  def self.bulk_mark_reviewed(transaction_ids, user_id, reviewed: true)
    # Delete anomalies for the specified transactions instead of marking as reviewed
    transactions = where(id: transaction_ids, user_id: user_id)
    anomaly_count = 0
    
    transactions.find_each do |transaction|
      deleted_count = transaction.anomalies.destroy_all.count
      anomaly_count += deleted_count
      Rails.logger.info "Deleted #{deleted_count} anomalies for transaction #{transaction.id}"
    end
    
    { deleted_anomalies: anomaly_count, transaction_count: transactions.count }
  end

  def self.bulk_delete(transaction_ids, user_id)
    where(id: transaction_ids, user_id: user_id).destroy_all
  end

  def self.bulk_apply_rules(user_id, transaction_ids = nil)
    BulkRuleApplicationJob.perform_later(user_id, transaction_ids)
  end

  def self.bulk_detect_anomalies(user_id, transaction_ids = nil)
    AnomalyDetectionService.bulk_detect_anomalies(user_id, transaction_ids)
  end

  def apply_rules_manually
    # Manually trigger rule application for this transaction
    apply_categorization_rules
  end

  private

  def skip_callbacks
    Rails.env.test? || caller.any? { |line| line.include?('db/seeds.rb') }
  end

  def check_for_anomalies
    AnomalyDetectionJob.perform_later(id)
  end

  def should_apply_categorization_rules_on_create?
    # Apply rules to new transactions that don't have a category
    category_id.nil?
  end

  def should_apply_categorization_rules_on_update?
    # Only apply rules if category_id changed to nil (e.g., category was removed)
    # This prevents infinite recursion when rules update the category
    saved_change_to_category_id? && category_id.nil?
  end

  def apply_categorization_rules
    # Add a guard to prevent recursion
    return if @applying_categorization_rules
    @applying_categorization_rules = true
    
    Rails.logger.info "Applying categorization rules to transaction #{id} (amount: #{amount}, description: #{description})"
    CategorizationEngine.apply_rules(self)
    
    # Log if a category was applied
    if saved_change_to_category_id?
      Rails.logger.info "Transaction #{id} categorized with category_id: #{category_id}"
    end
  ensure
    @applying_categorization_rules = false
  end

  def invalidate_user_cache
    CachingService.invalidate_user_cache(user_id, :dashboard)
    CachingService.invalidate_user_cache(user_id, :patterns)
  end

  def broadcast_update
    # TODO: Re-enable WebSocket broadcasting once ActionCable is properly configured
    # WebSocketService.broadcast_transaction_update(user_id, self, 'updated')
    # WebSocketService.broadcast_dashboard_update(user_id)
  end

  def broadcast_destroy
    # TODO: Re-enable WebSocket broadcasting once ActionCable is properly configured
    # WebSocketService.broadcast_transaction_update(user_id, self, 'deleted')
    # WebSocketService.broadcast_dashboard_update(user_id)
  end
end
