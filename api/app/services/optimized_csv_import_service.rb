require_relative '../channels/import_channel'

class OptimizedCsvImportService
  include ActiveModel::Model
  
  BATCH_SIZE = 10000
  
  attr_accessor :user, :file, :filename, :s3_key
  
  def initialize(user:, file: nil, filename: nil, s3_key: nil)
    @user = user
    @file = file
    @filename = filename
    @s3_key = s3_key
  end
  
  def create_import
    return { success: false, errors: ['No file provided'] } unless file || s3_key
    
    # For direct file uploads, we need to upload to S3 first
    if file.present? && s3_key.blank?
      # Generate S3 key for direct upload
      s3_key = "imports/#{user.id}/#{SecureRandom.uuid}/#{file.original_filename}"
      
      # Upload file to S3
      begin
        S3_CLIENT.put_object(
          bucket: S3_BUCKET,
          key: s3_key,
          body: file.read,
          content_type: file.content_type
        )
        
        # Reset file pointer
        file.rewind
      rescue => e
        return { success: false, errors: ["Failed to upload to S3: #{e.message}"] }
      end
    end
    
    csv_import = CsvImport.create!(
      user: user,
      filename: filename || file.original_filename,
      status: 'pending',
      total_rows: 0,
      s3_key: s3_key,
      file_size: file&.size,
      metadata: {
        content_type: file&.content_type,
        uploaded_at: Time.current.iso8601
      }
    )
    
    # Start background processing
    OptimizedCsvProcessingJob.perform_later(csv_import.id)
    
    { success: true, csv_import: csv_import }
  rescue => e
    { success: false, errors: [e.message] }
  end
  
  def self.generate_presigned_url(user, filename, content_type)
    s3_key = "imports/#{user.id}/#{SecureRandom.uuid}/#{filename}"
    
    presigner = Aws::S3::Presigner.new(client: S3_CLIENT)
    presigned_url = presigner.presigned_url(
      :put_object,
      bucket: S3_BUCKET,
      key: s3_key,
      content_type: content_type,
      expires_in: 3600 # 1 hour
    )
    
    {
      presigned_url: presigned_url,
      s3_key: s3_key,
      expires_in: 3600
    }
  end
  
  def self.process_file(csv_import)
    service = new(user: csv_import.user, s3_key: csv_import.s3_key)
    service.process_csv_import(csv_import)
  end
  
  def process_csv_import(csv_import)
    csv_import.update!(
      status: 'processing',
      started_at: Time.current
    )
    
    # Get file content from S3
    file_content = download_from_s3
    
    # Process CSV in streaming fashion to reduce memory usage
    total_rows = count_csv_rows(file_content)
    csv_import.update!(total_rows: total_rows)
    
    processed_rows = 0
    error_rows = 0
    errors = []
    
    # Phase 1: Bulk insert transactions (fast, no callbacks, streaming)
    all_created_transaction_ids = []
    process_csv_stream(file_content) do |batch, batch_index|
      batch_result = process_batch_optimized(batch, csv_import.user)
      processed_rows += batch_result[:processed]
      error_rows += batch_result[:errors]
      errors.concat(batch_result[:error_messages])
      all_created_transaction_ids.concat(batch_result[:created_transaction_ids] || [])
      
      csv_import.update!(
      processed_rows: processed_rows,
      error_rows: error_rows,
      metadata: csv_import.metadata.merge(
        last_processed_at: Time.current.iso8601,
        errors: errors.last(100) # Keep last 100 errors
      )
      )
      
      # Broadcast progress via WebSocket
      broadcast_progress(csv_import)
    end
    
    # Mark as completed
    csv_import.update!(
      status: 'completed',
      completed_at: Time.current,
      metadata: csv_import.metadata.merge(
        processing_stats: {
          total_rows: total_rows,
          processed_rows: processed_rows,
          error_rows: error_rows,
          success_rate: total_rows > 0 ? (processed_rows.to_f / total_rows * 100).round(2) : 0,
          processing_time: csv_import.processing_time_seconds,
          rows_per_second: csv_import.rows_per_second
        }
      )
    )
    
    # Clear all cached queries for the user after successful import
    CachingService.invalidate_user_cache(csv_import.user.id, :all)
    
    # Clean up S3 file
    delete_from_s3
    
    # Broadcast completion
    broadcast_completion(csv_import)
    
    # Phase 2: Queue post-processing jobs (async) with specific transaction IDs
    queue_post_processing_jobs(csv_import.user.id, csv_import.id, all_created_transaction_ids)
    
    { success: true, csv_import: csv_import }
  rescue => e
    csv_import.update!(
      status: 'failed',
      completed_at: Time.current,
      error_message: e.message
    )
    
    broadcast_error(csv_import, e.message)
    
    { success: false, error: e.message }
  end
  
  private
  
  def download_from_s3
    response = S3_CLIENT.get_object(
      bucket: S3_BUCKET,
      key: s3_key
    )
    response.body.read
  end
  
  def delete_from_s3
    S3_CLIENT.delete_object(
      bucket: S3_BUCKET,
      key: s3_key
    )
  rescue => e
    Rails.logger.error "Failed to delete S3 file #{s3_key}: #{e.message}"
  end
  
  def parse_csv(content)
    CSV.parse(content, headers: true, encoding: 'UTF-8')
  rescue => e
    raise "Invalid CSV format: #{e.message}"
  end
  
  def count_csv_rows(content)
    # Count rows without loading entire CSV into memory
    count = 0
    CSV.parse(content, headers: true, encoding: 'UTF-8') do |row|
      count += 1
    end
    count
  rescue => e
    raise "Invalid CSV format: #{e.message}"
  end
  
  def process_csv_stream(content)
    batch = []
    batch_index = 0
    line_number = 1
    
    # Use streaming CSV parsing with memory optimization
    CSV.parse(content, headers: true, encoding: 'UTF-8') do |row|
      # Add line number to each row for error tracking
      row.define_singleton_method(:line_number) { line_number }
      batch << row
      line_number += 1
      
      if batch.size >= BATCH_SIZE
        yield batch, batch_index
        batch.clear  # Clear array instead of reassigning for better memory management
        batch_index += 1
        
        # Force garbage collection every 10 batches to manage memory
        GC.start if batch_index % 10 == 0
      end
    end
    
    # Process remaining rows
    yield batch, batch_index if batch.any?
  rescue => e
    raise "Invalid CSV format: #{e.message}"
  end
  
  def process_batch_optimized(rows, user)
    processed = 0
    errors = 0
    error_messages = []
    transaction_attributes = []
    created_transaction_ids = []
    
    rows.each do |row|
      begin
        # Parse row data
        parsed_data = parse_row_data(row, user)
        
        if parsed_data
          transaction_attributes << {
            user_id: user.id,
            amount: parsed_data[:amount],
            description: parsed_data[:description],
            date: parsed_data[:date],
            category_id: parsed_data[:category_id],
            created_at: Time.current,
            updated_at: Time.current
          }
        else
          errors += 1
          error_messages << "Row #{row.line_number}: Invalid data"
        end
      rescue => e
        errors += 1
        error_messages << "Row #{row.line_number}: #{e.message}"
      end
    end
    
    # Bulk insert transactions (no callbacks, no validations)
    if transaction_attributes.any?
      begin
        # Use insert_all for maximum performance with connection optimization
        ActiveRecord::Base.connection_pool.with_connection do
          result = Transaction.insert_all(transaction_attributes, returning: [:id])
          created_transaction_ids = result.rows.flatten
        end
        processed = transaction_attributes.count
      rescue => e
        errors += transaction_attributes.count
        error_messages << "Batch insert error: #{e.message}"
      end
    end
    
    { processed: processed, errors: errors, error_messages: error_messages, created_transaction_ids: created_transaction_ids }
  end
  
  def parse_row_data(row, user)
    # Map CSV columns to transaction attributes
    amount = parse_amount(row['amount'])
    date = parse_date(row['date'])
    category_id = parse_category_id(row['category_id'], user)
    
    # Skip rows with invalid required data
    return nil if amount.nil? || date.nil? || row['description'].blank?
    
    {
      amount: amount,
      description: row['description']&.strip,
      date: date,
      category_id: category_id
    }
  end
  
  def parse_amount(amount_str)
    return nil if amount_str.blank?
    amount_str.to_f
  end
  
  def parse_date(date_str)
    return nil if date_str.blank?
    Date.parse(date_str)
  rescue
    nil
  end
  
  def parse_category_id(category_id_str, user)
    return nil if category_id_str.blank?
    
    category_id = category_id_str.to_i
    # Verify category belongs to user (cached lookup)
    @category_cache ||= user.categories.pluck(:id).to_set
    @category_cache.include?(category_id) ? category_id : nil
  end
  
  def parse_boolean(bool_str)
    return false if bool_str.blank?
    %w[true 1 yes].include?(bool_str.downcase)
  end
  
  
  def queue_post_processing_jobs(user_id, csv_import_id, transaction_ids = nil)
    # Queue categorization job with specific transaction IDs
    BulkCategorizationJob.perform_later(user_id, csv_import_id, transaction_ids)
    
    # Queue anomaly detection job with specific transaction IDs
    BulkAnomalyDetectionJob.perform_later(user_id, csv_import_id, transaction_ids)
  end
  
  def broadcast_progress(csv_import)
    begin
      ImportChannel.broadcast_progress(user, csv_import)
    rescue => e
      Rails.logger.error "Failed to broadcast progress: #{e.message}"
    end
    Rails.logger.info "CSV Import Progress: #{csv_import.progress_percentage}% (#{csv_import.processed_rows}/#{csv_import.total_rows})"
  end
  
  def broadcast_completion(csv_import)
    begin
      ImportChannel.broadcast_completion(user, csv_import)
    rescue => e
      Rails.logger.error "Failed to broadcast completion: #{e.message}"
    end
    Rails.logger.info "CSV Import Completed: #{csv_import.filename}"
  end
  
  def broadcast_error(csv_import, error_message)
    begin
      ImportChannel.broadcast_error(user, csv_import, error_message)
    rescue => e
      Rails.logger.error "Failed to broadcast error: #{e.message}"
    end
    Rails.logger.error "CSV Import Error: #{error_message}"
  end
end
