require_relative '../application_cable/connection'
require_relative '../application_cable/channel'

class ImportChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    
    stream_from "user_#{current_user.id}_imports"
    
    active_imports = current_user.csv_imports.where(status: ['pending', 'processing']).count
    transmit({
      type: 'import_status',
      active_imports: active_imports,
      timestamp: Time.current
    })
  end

  def unsubscribed; end
  
  def self.broadcast_progress(user, csv_import)
    ActionCable.server.broadcast("user_#{user.id}_imports", {
      type: 'progress',
      import_id: csv_import.id,
      status: csv_import.status,
      progress_percentage: csv_import.progress_percentage,
      processed_rows: csv_import.processed_rows,
      total_rows: csv_import.total_rows,
      error_rows: csv_import.error_rows,
      rows_per_second: csv_import.rows_per_second,
      timestamp: Time.current
    })
  end
  
  def self.broadcast_completion(user, csv_import)
    ActionCable.server.broadcast("user_#{user.id}_imports", {
      type: 'completed',
      import_id: csv_import.id,
      status: csv_import.status,
      progress_percentage: csv_import.progress_percentage,
      processed_rows: csv_import.processed_rows,
      total_rows: csv_import.total_rows,
      error_rows: csv_import.error_rows,
      processing_time_seconds: csv_import.processing_time_seconds,
      rows_per_second: csv_import.rows_per_second,
      success_rate: csv_import.total_rows > 0 ? (csv_import.processed_rows.to_f / csv_import.total_rows * 100).round(2) : 0,
      cache_cleared: true,
      timestamp: Time.current
    })
  end
  
  def self.broadcast_error(user, csv_import, error_message)
    ActionCable.server.broadcast("user_#{user.id}_imports", {
      type: 'error',
      import_id: csv_import.id,
      status: csv_import.status,
      error_message: error_message,
      timestamp: Time.current
    })
  end

end