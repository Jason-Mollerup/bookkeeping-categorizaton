class CategorizationEngine
  def self.apply_rules(transaction)
    return unless transaction.user_id
    # Skip if transaction already has a category to prevent infinite loops
    return if transaction.category_id.present?

    active_rules = CategorizationRule
      .where(user_id: transaction.user_id, active: true)
      .by_priority

    active_rules.each do |rule|
      if matches_rule?(transaction, rule)
        # Use update_column to bypass callbacks and prevent infinite recursion
        transaction.update_column(:category_id, rule.category_id)
        break # Apply only the first matching rule based on priority
      end
    end
  end

  def self.bulk_categorize(transaction_ids, category_id, user_id)
    return { success: false, error: "Invalid parameters" } if transaction_ids.blank? || category_id.blank?

    transactions = Transaction.where(id: transaction_ids, user_id: user_id)
    
    if transactions.count != transaction_ids.count
      return { success: false, error: "Some transactions not found or unauthorized" }
    end

    updated_count = transactions.update_all(category_id: category_id)
    { success: true, updated_count: updated_count }
  end

  def self.bulk_apply_rules(user_id, transaction_ids = nil)
    # Use the optimized version from BulkOperationsService
    BulkOperationsService.bulk_apply_rules_optimized(user_id, transaction_ids)
  end

  def self.create_rule_and_apply(user_id, rule_params)
    rule = CategorizationRule.new(rule_params.merge(user_id: user_id))
    
    if rule.save
      # Apply to existing uncategorized transactions
      result = bulk_apply_rules(user_id)
      { success: true, rule: rule, applied_to_existing: result[:updated_count] }
    else
      { success: false, errors: rule.errors.full_messages }
    end
  end

  private

  def self.matches_rule?(transaction, rule)
    rule.matches_transaction?(transaction)
  rescue => e
    Rails.logger.error "Error applying rule #{rule.id}: #{e.message}"
    false
  end
end
