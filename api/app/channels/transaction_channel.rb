require_relative '../application_cable/connection'
require_relative '../application_cable/channel'

class TransactionChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    
    stream_from "user_#{current_user.id}_transactions"

    summary = {
      total_count: current_user.transactions.count,
      uncategorized_count: current_user.transactions.uncategorized.count,
      recent_count: current_user.transactions.where(created_at: 1.hour.ago..Time.current).count
    }
    
    transmit({
      type: 'transaction_summary',
      summary: summary,
      timestamp: Time.current
    })
  end

  def unsubscribed; end

  def subscribe_to_category(category_id)
    return reject unless current_user
    
    category = current_user.categories.find(category_id)
    stream_from "user_#{current_user.id}_category_#{category_id}_transactions"
    
    transmit({
      type: 'category_subscribed',
      category: {
        id: category.id,
        name: category.name,
        color: category.color
      }
    })
  end

  def unsubscribe_from_category(category_id)
    stop_stream_from "user_#{current_user.id}_category_#{category_id}_transactions"
  end

  def get_recent_transactions(data = {})
    return reject unless current_user
    
    limit = [data['limit']&.to_i || 10, 50].min
    category_id = data['category_id']
    
    transactions = current_user.transactions
                             .includes(:category, :anomalies)
                             .order(created_at: :desc)
                             .limit(limit)
    
    transactions = transactions.where(category_id: category_id) if category_id

    transmit({
      type: 'recent_transactions',
      transactions: transactions.map { |t| transaction_json(t) },
      timestamp: Time.current
    })
  end

  def get_dashboard_data
    return reject unless current_user
    
    dashboard_data = CachingService.cache_dashboard_summary(current_user.id)
    
    transmit({
      type: 'dashboard_data',
      data: dashboard_data,
      timestamp: Time.current
    })
  end

  def bulk_categorize(data)
    return reject unless current_user
    
    transaction_ids = data['transaction_ids']
    category_id = data['category_id']
    
    return reject unless transaction_ids.is_a?(Array) && category_id

    result = Transaction.bulk_categorize(transaction_ids, category_id, current_user.id)
    
    if result[:success]
      broadcast_to_user({
        type: 'bulk_categorization_complete',
        updated_count: result[:updated_count],
        transaction_ids: transaction_ids,
        category_id: category_id
      })
    else
      transmit({
        type: 'error',
        message: result[:error]
      })
    end
  end

  def apply_rules(data = {})
    return reject unless current_user
    
    transaction_ids = data['transaction_ids']
    
    Transaction.bulk_apply_rules(current_user.id, transaction_ids)
    
    transmit({
      type: 'rules_application_started',
      message: 'Rules application started - you will be notified when complete'
    })
  end


  def broadcast_to_user(data)
    ActionCable.server.broadcast("user_#{current_user.id}_transactions", data)
  end

  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      category: transaction.category ? {
        id: transaction.category.id,
        name: transaction.category.name,
        color: transaction.category.color
      } : nil,
      anomalies_count: transaction.anomalies.unresolved.count,
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    }
  end
end
