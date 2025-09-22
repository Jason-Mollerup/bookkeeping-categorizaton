class ImportCsvJob < ApplicationJob
  queue_as :default

  def perform(user_id, file_url, file_name)
    user = User.find(user_id)
    
    # Broadcast import started
    broadcast_import_update(user_id, {
      type: 'import_started',
      file_name: file_name,
      status: 'processing',
      progress: 0,
      message: 'Starting CSV import...'
    })

    begin
      # Download and parse CSV file
      csv_data = download_csv_file(file_url)
      total_rows = csv_data.count
      
      broadcast_import_update(user_id, {
        type: 'import_progress',
        file_name: file_name,
        status: 'processing',
        progress: 10,
        message: "Found #{total_rows} rows to process"
      })

      # Convert CSV data to transaction attributes for bulk processing
      transactions_data = csv_data.map { |row| parse_csv_row(user, row) }.compact
      
      # Use optimized bulk import
      result = BulkOperationsService.bulk_import_transactions(user_id, transactions_data)
      
      created_count = result[:created_count]
      error_count = result[:error_count]
      created_transaction_ids = result[:created_transaction_ids] || []

      # Apply categorization rules to new transactions only
      broadcast_import_update(user_id, {
        type: 'import_progress',
        file_name: file_name,
        status: 'processing',
        progress: 95,
        message: 'Applying categorization rules...'
      })

      BulkOperationsService.bulk_apply_rules_optimized(user_id, created_transaction_ids)

      # Trigger anomaly detection on new transactions only
      broadcast_import_update(user_id, {
        type: 'import_progress',
        file_name: file_name,
        status: 'processing',
        progress: 98,
        message: 'Detecting anomalies...'
      })

      BulkOperationsService.bulk_detect_anomalies_optimized(user_id, created_transaction_ids)

      # Clear all cached queries for the user after successful import
      CachingService.invalidate_user_cache(user_id, :all)

      # Import completed
      broadcast_import_update(user_id, {
        type: 'import_completed',
        file_name: file_name,
        status: 'completed',
        progress: 100,
        total_processed: total_rows,
        created: created_count,
        errors: error_count,
        message: "Import completed successfully! Created #{created_count} transactions",
        cache_cleared: true
      })

    rescue => e
      Rails.logger.error "CSV import failed: #{e.message}"
      broadcast_import_update(user_id, {
        type: 'import_failed',
        file_name: file_name,
        status: 'failed',
        progress: 0,
        message: "Import failed: #{e.message}"
      })
    end
  end

  private

  def download_csv_file(file_url)
    # This would typically download from S3 or other storage
    # For now, we'll simulate with a placeholder
    require 'csv'
    
    # In a real implementation, you would:
    # 1. Download the file from S3 using AWS SDK
    # 2. Parse the CSV content
    # 3. Return the parsed data
    
    # Placeholder implementation
    []
  end

  def parse_csv_row(user, row)
    # Map CSV columns to transaction attributes
    # This would depend on the CSV format
    {
      amount: row['amount']&.to_f,
      description: row['description'],
      date: Date.parse(row['date']) rescue Date.current,
      category_id: find_category_by_name(user, row['category'])
    }
  rescue => e
    Rails.logger.error "Error parsing CSV row: #{e.message}"
    nil
  end

  def find_category_by_name(user, category_name)
    return nil unless category_name.present?
    
    user.categories.find_by('name ILIKE ?', "%#{category_name}%")&.id
  end

  def broadcast_import_update(user_id, data)
    ActionCable.server.broadcast("user_#{user_id}_imports", data)
  end
end
