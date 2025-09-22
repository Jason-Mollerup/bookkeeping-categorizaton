class BulkImportJob < ApplicationJob
  queue_as :default

  def perform(user_id, transactions_data, import_id = nil)
    user = User.find(user_id)
    
    # Broadcast import started
    broadcast_import_update(user_id, {
      type: 'import_started',
      import_id: import_id,
      total_rows: transactions_data.count,
      status: 'processing',
      progress: 0,
      message: 'Starting bulk import...'
    })

    begin
      total_rows = transactions_data.count
      processed_count = 0
      created_count = 0
      error_count = 0
      all_created_transaction_ids = []

      # Process in batches for memory efficiency
      transactions_data.each_slice(1000) do |batch|
        result = process_batch(user, batch)
        
        created_count += result[:created_count]
        error_count += result[:error_count]
        processed_count += batch.count
        all_created_transaction_ids.concat(result[:created_transaction_ids] || [])

        # Broadcast progress update
        progress = ((processed_count.to_f / total_rows) * 90).round + 10
        broadcast_import_update(user_id, {
          type: 'import_progress',
          import_id: import_id,
          status: 'processing',
          progress: progress,
          processed: processed_count,
          total: total_rows,
          created: created_count,
          errors: error_count,
          message: "Processed #{processed_count}/#{total_rows} rows"
        })
      end

      # Apply categorization rules to new transactions only
      broadcast_import_update(user_id, {
        type: 'import_progress',
        import_id: import_id,
        status: 'processing',
        progress: 95,
        message: 'Applying categorization rules...'
      })

      BulkOperationsService.bulk_apply_rules_optimized(user_id, all_created_transaction_ids)

      # Trigger anomaly detection on new transactions only
      broadcast_import_update(user_id, {
        type: 'import_progress',
        import_id: import_id,
        status: 'processing',
        progress: 98,
        message: 'Detecting anomalies...'
      })

      BulkOperationsService.bulk_detect_anomalies_optimized(user_id, all_created_transaction_ids)

      # Clear all cached queries for the user after successful import
      CachingService.invalidate_user_cache(user_id, :all)

      # Import completed
      broadcast_import_update(user_id, {
        type: 'import_completed',
        import_id: import_id,
        status: 'completed',
        progress: 100,
        total_processed: processed_count,
        created: created_count,
        errors: error_count,
        message: "Import completed successfully! Created #{created_count} transactions",
        cache_cleared: true
      })

    rescue => e
      Rails.logger.error "Bulk import failed: #{e.message}"
      broadcast_import_update(user_id, {
        type: 'import_failed',
        import_id: import_id,
        status: 'failed',
        progress: 0,
        message: "Import failed: #{e.message}"
      })
    end
  end

  private

  def process_batch(user, batch)
    created_count = 0
    error_count = 0
    created_transaction_ids = []

    begin
      # Prepare transaction attributes for bulk insert
      transaction_attributes = batch.map do |data|
        {
          user_id: user.id,
          amount: data[:amount],
          description: data[:description],
          date: data[:date],
          category_id: data[:category_id],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Bulk insert for performance and capture created IDs
      result = Transaction.insert_all(transaction_attributes, returning: [:id])
      created_count = batch.count
      created_transaction_ids = result.rows.flatten

    rescue => e
      Rails.logger.error "Batch processing error: #{e.message}"
      error_count = batch.count
    end

    { created_count: created_count, error_count: error_count, created_transaction_ids: created_transaction_ids }
  end

  def broadcast_import_update(user_id, data)
    ActionCable.server.broadcast("user_#{user_id}_imports", data)
  end
end
