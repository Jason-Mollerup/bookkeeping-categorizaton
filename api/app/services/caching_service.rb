class CachingService
  CACHE_EXPIRY = 1.hour

  def self.cache_user_categories(user_id)
    Rails.cache.fetch("user_#{user_id}_categories", expires_in: CACHE_EXPIRY) do
      Category.where(user_id: user_id).pluck(:id, :name, :color).map do |id, name, color|
        { id: id, name: name, color: color }
      end
    end
  end

  def self.cache_user_rules(user_id)
    Rails.cache.fetch("user_#{user_id}_active_rules", expires_in: CACHE_EXPIRY) do
      CategorizationRule.where(user_id: user_id, active: true)
                       .by_priority
                       .includes(:category)
                       .map do |rule|
        {
          id: rule.id,
          name: rule.name,
          rule_predicate: rule.rule_predicate,
          category_id: rule.category_id,
          priority: rule.priority
        }
      end
    end
  end

  def self.cache_dashboard_summary(user_id)
    Rails.cache.fetch("user_#{user_id}_dashboard_summary", expires_in: 30.minutes) do
      # Use single query with aggregations for better performance
      stats = Transaction.where(user_id: user_id)
                        .group('1')
                        .select(
                          'COUNT(*) as total_transactions',
                          'COUNT(CASE WHEN category_id IS NULL THEN 1 END) as uncategorized_count',
                        ).first

      anomaly_count = Anomaly.joins(:transaction_record)
                             .where(transactions: { user_id: user_id })
                             .unresolved.count

      recent_transactions = Transaction.where(user_id: user_id)
                                      .order(created_at: :desc)
                                      .limit(5)
                                      .pluck(:id, :amount, :description, :date)

      {
        total_transactions: stats&.total_transactions || 0,
        uncategorized_count: stats&.uncategorized_count || 0,
        anomaly_count: anomaly_count,
        recent_transactions: recent_transactions
      }
    end
  end

  def self.cache_user_spending_patterns(user_id)
    Rails.cache.fetch("user_#{user_id}_spending_patterns", expires_in: 2.hours) do
      transactions = Transaction.where(user_id: user_id)
                               .where.not(amount: nil)
                               .pluck(:amount)
      
      return {} if transactions.empty?

      {
        mean: transactions.sum / transactions.count.to_f,
        median: transactions.sort[transactions.count / 2],
        standard_deviation: calculate_standard_deviation(transactions),
        min: transactions.min,
        max: transactions.max,
        count: transactions.count
      }
    end
  end

  def self.cache_uncategorized_transactions(user_id, limit = 100)
    Rails.cache.fetch("user_#{user_id}_uncategorized_#{limit}", expires_in: 15.minutes) do
      Transaction.where(user_id: user_id, category_id: nil)
                .order(created_at: :desc)
                .limit(limit)
                .pluck(:id, :amount, :description, :date, :created_at)
    end
  end

  def self.cache_anomaly_summary(user_id)
    Rails.cache.fetch("user_#{user_id}_anomaly_summary", expires_in: 10.minutes) do
      {
        total_unresolved: current_user.anomalies.unresolved.count,
        by_severity: current_user.anomalies.unresolved
                                .group(:severity)
                                .count,
        by_type: current_user.anomalies.unresolved
                             .group(:anomaly_type)
                             .count
      }
    end
  end

  def self.cache_category_stats(user_id)
    Rails.cache.fetch("user_#{user_id}_category_stats", expires_in: 1.hour) do
      Category.joins(:transactions)
              .where(user_id: user_id)
              .group('categories.id', 'categories.name', 'categories.color')
              .select(
                'categories.id',
                'categories.name', 
                'categories.color',
                'COUNT(transactions.id) as transaction_count',
                'SUM(transactions.amount) as total_amount',
                'AVG(transactions.amount) as average_amount'
              )
              .map { |c| {
                id: c.id,
                name: c.name,
                color: c.color,
                transaction_count: c.transaction_count,
                total_amount: c.total_amount,
                average_amount: c.average_amount
              }}
    end
  end

  def self.invalidate_user_cache(user_id, cache_type = :all)
    case cache_type
    when :categories
      Rails.cache.delete("user_#{user_id}_categories")
    when :rules
      Rails.cache.delete("user_#{user_id}_active_rules")
    when :dashboard
      Rails.cache.delete("user_#{user_id}_dashboard_summary")
    when :patterns
      Rails.cache.delete("user_#{user_id}_spending_patterns")
    when :uncategorized
      Rails.cache.delete_matched("user_#{user_id}_uncategorized_*")
    when :anomalies
      Rails.cache.delete("user_#{user_id}_anomaly_summary")
    when :category_stats
      Rails.cache.delete("user_#{user_id}_category_stats")
    when :all
      Rails.cache.delete_matched("user_#{user_id}_*")
    end
  end

  private

  def self.calculate_standard_deviation(values)
    mean = values.sum / values.count.to_f
    variance = values.sum { |x| (x - mean) ** 2 } / values.count.to_f
    Math.sqrt(variance)
  end
end
