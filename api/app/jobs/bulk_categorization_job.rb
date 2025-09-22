class BulkCategorizationJob < ApplicationJob
  queue_as :post_processing
  retry_on StandardError, wait: :exponentially_longer, attempts: 2
  discard_on ActiveRecord::RecordNotFound
  
  def perform(user_id, csv_import_id = nil, transaction_ids = nil)
    user = User.find(user_id)
    
    # Broadcast categorization started
    broadcast_update(user_id, {
      type: 'categorization_started',
      message: 'Applying categorization rules to new transactions...'
    })
    
    begin
      # If we have specific transaction IDs, use those (most efficient)
      if transaction_ids.present?
        total_transactions = transaction_ids.count
        if total_transactions == 0
          broadcast_update(user_id, {
            type: 'categorization_completed',
            message: 'No transactions to categorize',
            processed_count: 0
          })
          return
        end
        
        # Apply categorization rules to specific transactions
        result = BulkOperationsService.bulk_apply_rules_optimized(user_id, transaction_ids)
      else
        # Fallback to time-based filtering for backward compatibility
        scope = user.transactions.uncategorized
        
        if csv_import_id
          csv_import = CsvImport.find(csv_import_id)
          scope = scope.where(
            created_at: (csv_import.completed_at - 5.minutes)..(csv_import.completed_at + 5.minutes)
          )
        end
        
        total_transactions = scope.count
        
        if total_transactions == 0
          broadcast_update(user_id, {
            type: 'categorization_completed',
            message: 'No uncategorized transactions found',
            processed_count: 0
          })
          return
        end
        
        # Apply categorization rules to all matching transactions
        result = BulkOperationsService.bulk_apply_rules_optimized(user_id)
      end
      
      broadcast_update(user_id, {
        type: 'categorization_completed',
        message: "Categorization completed: #{result[:updated_count]} transactions categorized",
        processed_count: result[:updated_count]
      })
      
    rescue => e
      Rails.logger.error "Bulk categorization failed: #{e.message}"
      broadcast_update(user_id, {
        type: 'categorization_failed',
        message: "Categorization failed: #{e.message}"
      })
    end
  end
  
  private
  
  def broadcast_update(user_id, data)
    begin
      ActionCable.server.broadcast("user_#{user_id}_imports", data)
    rescue => e
      Rails.logger.error "Failed to broadcast categorization update: #{e.message}"
    end
    Rails.logger.info "Categorization update: #{data[:message]}"
  end
end