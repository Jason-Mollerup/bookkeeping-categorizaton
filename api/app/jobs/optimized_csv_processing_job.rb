class OptimizedCsvProcessingJob < ApplicationJob
  queue_as :import_processing
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound
  
  def perform(csv_import_id)
    csv_import = CsvImport.find(csv_import_id)
    
    # Skip if already processing or completed
    return if csv_import.processing? || csv_import.completed?
    
    # Mark as processing
    csv_import.update!(status: 'processing', started_at: Time.current)
    
    # Process the CSV file using optimized service
    result = OptimizedCsvImportService.process_file(csv_import)
    
    if result[:success]
      Rails.logger.info "Optimized CSV import #{csv_import_id} completed successfully"
    else
      Rails.logger.error "Optimized CSV import #{csv_import_id} failed: #{result[:error]}"
    end
  rescue => e
    Rails.logger.error "Optimized CSV processing job failed for import #{csv_import_id}: #{e.message}"
    
    # Update import status to failed
    csv_import&.update!(
      status: 'failed',
      completed_at: Time.current,
      error_message: e.message
    )
    
    # Re-raise to trigger job retry mechanism
    raise e
  end
end
