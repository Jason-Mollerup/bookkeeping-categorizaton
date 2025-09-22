class Api::V1::DashboardController < Api::V1::BaseController
  def summary
    summary_data = CachingService.cache_dashboard_summary(current_user.id)
    render json: { summary: summary_data }
  end

  def spending_trends
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : 12.months.ago
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current

    trends = {
      monthly_spending: monthly_spending_data(start_date, end_date),
      monthly_spending_by_category: monthly_spending_by_category_data(start_date, end_date),
      category_breakdown: category_breakdown_data(start_date, end_date),
      spending_patterns: CachingService.cache_user_spending_patterns(current_user.id)
    }

    render json: { trends: trends }
  end

  def recent_activity
    recent_transactions = current_user.transactions
                                    .includes(:category)
                                    .order(created_at: :desc)
                                    .limit(10)

    recent_anomalies = current_user.anomalies
                                  .unresolved
                                  .includes(:transaction_record)
                                  .order(created_at: :desc)
                                  .limit(5)

    render json: {
      recent_transactions: recent_transactions.map { |t| {
        id: t.id,
        amount: t.amount,
        description: t.description,
        category: t.category&.name,
        date: t.date,
        created_at: t.created_at
      }},
      recent_anomalies: recent_anomalies.map { |a| {
        id: a.id,
        type: a.anomaly_type,
        severity: a.severity,
        description: a.description,
        transaction_amount: a.transaction_record.amount,
        created_at: a.created_at
      }}
    }
  end

  private

  def monthly_spending_data(start_date, end_date)
    current_user.transactions
                .where(date: start_date..end_date)
                .group("DATE_TRUNC('month', date)")
                .sum(:amount)
                .map { |date, amount| { month: date.strftime('%Y-%m'), amount: amount } }
                .sort_by { |item| item[:month] }
  end

  def monthly_spending_by_category_data(start_date, end_date)
    # Get monthly spending data grouped by category
    data = current_user.transactions
                      .joins(:category)
                      .where(date: start_date..end_date)
                      .group("DATE_TRUNC('month', date)", 'categories.name', 'categories.color')
                      .sum(:amount)
                      .map { |(date, name, color), amount| {
                        month: date.strftime('%Y-%m'),
                        category: name,
                        color: color,
                        amount: amount
                      }}
                      .sort_by { |item| [item[:month], item[:category]] }

    # Transform data for easier frontend consumption
    months = data.map { |item| item[:month] }.uniq.sort
    categories = data.map { |item| item[:category] }.uniq.sort

    # Create a matrix where each month has all categories with amounts
    months.map do |month|
      month_data = { month: month }
      categories.each do |category|
        category_data = data.find { |item| item[:month] == month && item[:category] == category }
        month_data[category] = category_data ? category_data[:amount] : 0
      end
      month_data
    end
  end

  def category_breakdown_data(start_date, end_date)
    current_user.transactions
                .joins(:category)
                .where(date: start_date..end_date)
                .group('categories.name', 'categories.color')
                .sum(:amount)
                .map { |(name, color), amount| { 
                  category: name, 
                  color: color, 
                  amount: amount 
                }}
                .sort_by { |item| -item[:amount] }
  end
end
