class BulkRuleApplicationJob < ApplicationJob
  queue_as :default

  def perform(user_id, transaction_ids = nil)
    result = CategorizationEngine.bulk_apply_rules(user_id, transaction_ids)
    
    if result[:success]
      Rails.logger.info "Bulk rule application completed: #{result[:updated_count]} transactions updated"
      
      # Broadcast update via ActionCable
      ActionCable.server.broadcast(
        "user_#{user_id}_transactions",
        { 
          type: 'bulk_rule_application_complete',
          updated_count: result[:updated_count],
          timestamp: Time.current
        }
      )
    else
      Rails.logger.error "Bulk rule application failed: #{result[:error]}"
      
      # Broadcast error via ActionCable
      ActionCable.server.broadcast(
        "user_#{user_id}_transactions",
        { 
          type: 'bulk_rule_application_failed',
          error: result[:error],
          timestamp: Time.current
        }
      )
    end
  rescue => e
    Rails.logger.error "Bulk rule application job failed: #{e.message}"
    raise e
  end
end
