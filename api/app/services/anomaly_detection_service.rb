class AnomalyDetectionService
  Z_SCORE_THRESHOLD = 2.5 # Flag transactions with Z-score > 2.5

  def self.detect_anomalies(transaction)
    anomalies = []
    
    anomalies << detect_unusual_amount(transaction)
    anomalies << detect_duplicate(transaction)
    anomalies << detect_missing_description(transaction)
    
    anomalies.compact.each do |anomaly_data|
      transaction.anomalies.create!(anomaly_data)
    end
  end

  def self.bulk_detect_anomalies(user_id, transaction_ids = nil)
    scope = Transaction.where(user_id: user_id)
    scope = scope.where(id: transaction_ids) if transaction_ids.present?
    
    detected_count = 0
    
    scope.find_each do |transaction|
      # Only check transactions without existing anomalies
      next if transaction.anomalies.unresolved.exists?
      
      detect_anomalies(transaction)
      detected_count += 1
    end
    
    { success: true, detected_count: detected_count }
  end

  def self.resolve_anomalies(anomaly_ids, user_id)
    anomalies = Anomaly.joins(:transaction_record)
                       .where(id: anomaly_ids, transactions: { user_id: user_id })
    
    if anomalies.count != anomaly_ids.count
      return { success: false, error: "Some anomalies not found or unauthorized" }
    end

    updated_count = anomalies.update_all(resolved: true)
    { success: true, resolved_count: updated_count }
  end

  private

  def self.detect_unusual_amount(transaction)
    return nil unless transaction.amount.present?

    user_transactions = Transaction.where(user_id: transaction.user_id)
                                  .where.not(id: transaction.id)
                                  .where.not(amount: nil)
                                  .pluck(:amount)

    return nil if user_transactions.count < 10 # Need sufficient data for Z-score

    mean = user_transactions.sum / user_transactions.count.to_f
    variance = user_transactions.sum { |x| (x - mean) ** 2 } / user_transactions.count.to_f
    standard_deviation = Math.sqrt(variance)

    return nil if standard_deviation.zero?

    z_score = (transaction.amount - mean) / standard_deviation

    if z_score.abs > Z_SCORE_THRESHOLD
      {
        anomaly_type: 'unusual_amount',
        severity: z_score.abs > 4 ? 'critical' : z_score.abs > 3 ? 'high' : 'medium',
        description: "Transaction amount (#{transaction.amount}) is #{z_score > 0 ? 'unusually high' : 'unusually low'} (Z-score: #{z_score.round(2)})"
      }
    end
  end

  def self.detect_duplicate(transaction)
    return nil unless transaction.amount.present? && transaction.date.present?

    # Look for transactions with same amount, date, and similar description
    similar_transactions = Transaction.where(user_id: transaction.user_id)
                                     .where.not(id: transaction.id)
                                     .where(amount: transaction.amount)
                                     .where(date: transaction.date)
                                     .where(description: transaction.description)

    if similar_transactions.exists?
      {
        anomaly_type: 'duplicate',
        severity: 'high',
        description: "Potential duplicate transaction: same amount (#{transaction.amount}) and date (#{transaction.date})"
      }
    end
  end

  def self.detect_missing_description(transaction)
    if transaction.description.blank?
      {
        anomaly_type: 'missing_description',
        severity: 'low',
        description: "Missing required field: description"
      }
    end
  end
end
