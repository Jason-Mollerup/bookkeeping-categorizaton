class AnomalyDetectionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 2
  discard_on ActiveRecord::RecordNotFound

  def perform(transaction_id)
    # Ensure WebSocketService is loaded
    require_relative '../services/websocket_service' unless defined?(WebSocketService)
    transaction = Transaction.find(transaction_id)
    AnomalyDetectionService.detect_anomalies(transaction)
    
    Rails.logger.info "Anomaly detection completed for transaction #{transaction_id}"
    
    # Broadcast anomaly detection via ActionCable
    ActionCable.server.broadcast(
      "user_#{transaction.user_id}_anomalies",
      { 
        type: 'anomaly_detected',
        transaction_id: transaction_id,
        anomalies_count: transaction.anomalies.unresolved.count,
        timestamp: Time.current
      }
    )
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Transaction #{transaction_id} not found for anomaly detection"
  rescue => e
    Rails.logger.error "Anomaly detection job failed: #{e.message}"
    raise e
  end
end
