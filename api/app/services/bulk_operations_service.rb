class BulkOperationsService
  BATCH_SIZE = 50000

  def self.bulk_categorize_optimized(transaction_ids, category_id, user_id)
    return { success: false, error: "Invalid parameters" } if transaction_ids.blank? || category_id.blank?

    # Validate all transactions belong to user
    valid_ids = Transaction.where(id: transaction_ids, user_id: user_id).pluck(:id)
    
    if valid_ids.count != transaction_ids.count
      return { success: false, error: "Some transactions not found or unauthorized" }
    end

    # Process in batches to avoid memory issues
    updated_count = 0
    valid_ids.each_slice(BATCH_SIZE) do |batch|
      updated_count += Transaction.where(id: batch).update_all(category_id: category_id)
    end

    # Invalidate relevant caches
    CachingService.invalidate_user_cache(user_id, :dashboard)
    CachingService.invalidate_user_cache(user_id, :uncategorized)
    CachingService.invalidate_user_cache(user_id, :category_stats)

    { success: true, updated_count: updated_count }
  end

  def self.bulk_import_transactions(user_id, transactions_data)
    return { success: false, error: "No transaction data provided" } if transactions_data.blank?

    created_count = 0
    error_count = 0
    errors = []
    created_transaction_ids = []

    # Process in batches
    transactions_data.each_slice(BATCH_SIZE) do |batch|
      begin
        # Use bulk insert for better performance
        transaction_attributes = batch.map do |data|
          {
            user_id: user_id,
            amount: data[:amount],
            description: data[:description],
            date: data[:date],
            category_id: data[:category_id],
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # Bulk insert and capture the created IDs
        result = Transaction.insert_all(transaction_attributes, returning: [:id])
        created_count += batch.count
        created_transaction_ids.concat(result.rows.flatten)

      rescue => e
        error_count += batch.count
        errors << "Batch error: #{e.message}"
      end
    end

    # Invalidate caches
    CachingService.invalidate_user_cache(user_id, :all)

    {
      success: true,
      created_count: created_count,
      error_count: error_count,
      errors: errors,
      created_transaction_ids: created_transaction_ids
    }
  end

  def self.bulk_apply_rules_optimized(user_id, transaction_ids = nil)
    # Get active rules once
    active_rules = CategorizationRule.where(user_id: user_id, active: true)
                                   .by_priority
                                   .includes(:category)

    return { success: true, updated_count: 0 } if active_rules.empty?

    # Build scope for transactions to process
    scope = Transaction.where(user_id: user_id, category_id: nil)
    scope = scope.where(id: transaction_ids) if transaction_ids.present?

    updated_count = 0

    # Process in batches
    scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      # Group transactions by matching rule for bulk updates
      rule_groups = {}
      
      batch.each do |transaction|
        # Apply first matching rule
        matching_rule = active_rules.find { |rule| matches_rule?(transaction, rule) }
        
        if matching_rule
          rule_groups[matching_rule] ||= []
          rule_groups[matching_rule] << transaction.id
        end
      end
      
      # Perform bulk updates for each rule group
      rule_groups.each do |rule, transaction_ids|
        update_count = Transaction.where(id: transaction_ids)
                                 .update_all(category_id: rule.category_id)
        updated_count += update_count
      end
    end

    # Invalidate caches
    CachingService.invalidate_user_cache(user_id, :dashboard)
    CachingService.invalidate_user_cache(user_id, :uncategorized)

    { success: true, updated_count: updated_count }
  end

  def self.bulk_detect_anomalies_optimized(user_id, transaction_ids = nil)
    scope = Transaction.where(user_id: user_id)
    scope = scope.where(id: transaction_ids) if transaction_ids.present?

    detected_count = 0
    anomaly_attributes = []

    # Get user's spending patterns for Z-score calculation
    user_patterns = CachingService.cache_user_spending_patterns(user_id)
    return { success: true, detected_count: 0 } if user_patterns[:count] < 10

    # Pre-load transaction IDs that already have unresolved anomalies to avoid N+1 queries
    existing_anomaly_transaction_ids = Anomaly.where(resolved: false)
                                             .joins(:transaction_record)
                                             .where(transactions: { user_id: user_id })
                                             .pluck(:transaction_id)
                                             .to_set

    # Detect duplicates first (bulk operation)
    duplicate_anomalies = detect_duplicates_bulk(scope, existing_anomaly_transaction_ids)
    anomaly_attributes.concat(duplicate_anomalies)
    detected_count += duplicate_anomalies.count

    # Detect other anomalies (unusual amounts, missing metadata)
    scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      batch.each do |transaction|
        # Skip if already has unresolved anomalies (using pre-loaded data)
        next if existing_anomaly_transaction_ids.include?(transaction.id)

        anomalies = detect_anomalies_for_transaction(transaction, user_patterns)
        
        if anomalies.any?
          anomalies.each do |anomaly_data|
            anomaly_attributes << {
              transaction_id: transaction.id,
              anomaly_type: anomaly_data[:anomaly_type],
              severity: anomaly_data[:severity],
              description: anomaly_data[:description],
              resolved: false,
              created_at: Time.current,
              updated_at: Time.current
            }
          end
          detected_count += 1
        end
      end
    end

    # Bulk insert anomalies
    if anomaly_attributes.any?
      Anomaly.insert_all(anomaly_attributes)
    end

    # Invalidate caches
    CachingService.invalidate_user_cache(user_id, :anomalies)

    { success: true, detected_count: detected_count }
  end

  def self.bulk_delete_optimized(transaction_ids, user_id)
    return { success: false, error: "No transaction IDs provided" } if transaction_ids.blank?

    # Validate all transactions belong to user
    valid_ids = Transaction.where(id: transaction_ids, user_id: user_id).pluck(:id)
    
    if valid_ids.count != transaction_ids.count
      return { success: false, error: "Some transactions not found or unauthorized" }
    end

    deleted_count = 0

    # Process in batches to avoid memory issues
    valid_ids.each_slice(BATCH_SIZE) do |batch|
      deleted_count += Transaction.where(id: batch).delete_all
    end

    # Invalidate caches
    CachingService.invalidate_user_cache(user_id, :all)

    { success: true, deleted_count: deleted_count }
  end

  private

  def self.matches_rule?(transaction, rule)
    # Use the new rule structure with rule_predicate JSON
    rule.matches_transaction?(transaction)
  rescue => e
    Rails.logger.error "Error applying rule #{rule.id}: #{e.message}"
    false
  end

  def self.detect_duplicates_bulk(scope, existing_anomaly_transaction_ids)
    anomaly_attributes = []
    
    # Find duplicate groups using SQL grouping for efficiency
    duplicate_groups = scope
      .select("description, date, amount, category_id, COUNT(*) as count")
      .group(:description, :date, :amount, :category_id)
      .having("COUNT(*) > 1")

    duplicate_groups.each do |group|
      # Get all transaction IDs in this duplicate group
      transaction_ids = scope.where(
        description: group.description,
        date: group.date,
        amount: group.amount,
        category_id: group.category_id
      ).pluck(:id)
      
      # Skip transactions that already have unresolved anomalies
      valid_transaction_ids = transaction_ids.reject { |id| existing_anomaly_transaction_ids.include?(id) }
      
      # Create anomaly records for all transactions in the duplicate group
      valid_transaction_ids.each do |transaction_id|
        anomaly_attributes << {
          transaction_id: transaction_id,
          anomaly_type: 'duplicate',
          severity: 'high',
          description: "Potential duplicate transaction: same amount (#{group.amount}), date (#{group.date}), and description (#{group.description})",
          resolved: false,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    anomaly_attributes
  end

  def self.detect_anomalies_for_transaction(transaction, user_patterns)
    anomalies = []

    # Unusual amount detection
    if transaction.amount.present? && user_patterns[:standard_deviation] > 0
      z_score = (transaction.amount - user_patterns[:mean]) / user_patterns[:standard_deviation]
      
      if z_score.abs > 2.5
        anomalies << {
          anomaly_type: 'unusual_amount',
          severity: z_score.abs > 4 ? 'critical' : z_score.abs > 3 ? 'high' : 'medium',
          description: "Transaction amount (#{transaction.amount}) is #{z_score > 0 ? 'unusually high' : 'unusually low'} (Z-score: #{z_score.round(2)})"
        }
      end
    end

    # Missing description detection
    if transaction.description.blank?
      anomalies << {
        anomaly_type: 'missing_description',
        severity: 'low',
        description: "Missing required field: description"
      }
    end

    anomalies
  end
end
