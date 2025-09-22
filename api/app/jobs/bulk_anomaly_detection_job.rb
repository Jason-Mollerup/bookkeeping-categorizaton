class BulkAnomalyDetectionJob < ApplicationJob
  queue_as :post_processing
  retry_on StandardError, wait: :exponentially_longer, attempts: 2
  discard_on ActiveRecord::RecordNotFound
  
  def perform(user_id, csv_import_id = nil, transaction_ids = nil)
    user = User.find(user_id)
    
    # Broadcast anomaly detection started
    broadcast_update(user_id, {
      type: 'anomaly_detection_started',
      message: 'Detecting anomalies in new transactions...'
    })
    
    begin
      # If we have specific transaction IDs, use those (most efficient)
      if transaction_ids.present?
        total_transactions = transaction_ids.count
        if total_transactions == 0
          broadcast_update(user_id, {
            type: 'anomaly_detection_completed',
            message: 'No transactions to analyze for anomalies',
            detected_count: 0
          })
          return
        end
        
        # Run anomaly detection on specific transactions
        result = BulkOperationsService.bulk_detect_anomalies_optimized(user_id, transaction_ids)
      else
        # Fallback to time-based filtering for backward compatibility
        scope = user.transactions.left_joins(:anomalies)
                             .where(anomalies: { id: nil })
        
        if csv_import_id
          csv_import = CsvImport.find(csv_import_id)
          scope = scope.where(
            created_at: (csv_import.completed_at - 5.minutes)..(csv_import.completed_at + 5.minutes)
          )
        end
        
        total_transactions = scope.count
        
        if total_transactions == 0
          broadcast_update(user_id, {
            type: 'anomaly_detection_completed',
            message: 'No transactions found for anomaly detection',
            detected_count: 0
          })
          return
        end
        
        # Run anomaly detection on all matching transactions
        result = BulkOperationsService.bulk_detect_anomalies_optimized(user_id)
      end
      
      broadcast_update(user_id, {
        type: 'anomaly_detection_completed',
        message: "Anomaly detection completed: #{result[:detected_count]} anomalies found",
        detected_count: result[:detected_count]
      })
      
    rescue => e
      Rails.logger.error "Bulk anomaly detection failed: #{e.message}"
      broadcast_update(user_id, {
        type: 'anomaly_detection_failed',
        message: "Anomaly detection failed: #{e.message}"
      })
    end
  end
  
  private
  
  def broadcast_update(user_id, data)
    begin
      ActionCable.server.broadcast("user_#{user_id}_imports", data)
    rescue => e
      Rails.logger.error "Failed to broadcast anomaly detection update: #{e.message}"
    end
    Rails.logger.info "Anomaly detection update: #{data[:message]}"
  end
end
