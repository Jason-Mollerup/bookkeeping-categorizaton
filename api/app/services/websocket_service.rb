class WebSocketService
  def self.broadcast_transaction_update(user_id, transaction, action = 'updated')
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: "transaction_#{action}",
        transaction: {
          id: transaction.id,
          amount: transaction.amount,
          description: transaction.description,
          date: transaction.date,
          category: transaction.category ? {
            id: transaction.category.id,
            name: transaction.category.name,
            color: transaction.category.color
          } : nil,
          anomalies_count: transaction.anomalies.unresolved.count
        },
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_anomaly_detected(user_id, anomaly)
    ActionCable.server.broadcast(
      "user_#{user_id}_anomalies",
      {
        type: 'anomaly_detected',
        anomaly: {
          id: anomaly.id,
          type: anomaly.anomaly_type,
          severity: anomaly.severity,
          description: anomaly.description,
          transaction_id: anomaly.transaction_id
        },
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_anomaly_resolved(user_id, anomaly_id)
    ActionCable.server.broadcast(
      "user_#{user_id}_anomalies",
      {
        type: 'anomaly_resolved',
        anomaly_id: anomaly_id,
        remaining_count: User.find(user_id).anomalies.unresolved.count,
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_category_update(user_id, category, action = 'updated')
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: "category_#{action}",
        category: {
          id: category.id,
          name: category.name,
          color: category.color,
          transaction_count: category.transactions.count
        },
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_rule_update(user_id, rule, action = 'updated')
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: "rule_#{action}",
        rule: {
          id: rule.id,
          name: rule.name,
          rule_predicate: rule.rule_predicate,
          active: rule.active,
          priority: rule.priority
        },
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_dashboard_update(user_id)
    dashboard_data = CachingService.cache_dashboard_summary(user_id)
    
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: 'dashboard_updated',
        data: dashboard_data,
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_import_progress(user_id, progress_data)
    ActionCable.server.broadcast(
      "user_#{user_id}_imports",
      progress_data.merge(timestamp: Time.current)
    )
  end

  def self.broadcast_bulk_operation_complete(user_id, operation_type, result)
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: "#{operation_type}_complete",
        result: result,
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_bulk_operation_failed(user_id, operation_type, error)
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: "#{operation_type}_failed",
        error: error,
        timestamp: Time.current
      }
    )
  end

  def self.broadcast_system_notification(user_id, message, type = 'info')
    ActionCable.server.broadcast(
      "user_#{user_id}_transactions",
      {
        type: 'system_notification',
        message: message,
        notification_type: type,
        timestamp: Time.current
      }
    )
  end
end
