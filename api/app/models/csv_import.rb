class CsvImport < ApplicationRecord
  belongs_to :user
  
  validates :filename, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
  validates :total_rows, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  
  def progress_percentage
    return 0 if total_rows.zero?
    (processed_rows.to_f / total_rows * 100).round(2)
  end
  
  def completed?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def processing?
    status == 'processing'
  end
  
  def pending?
    status == 'pending'
  end
  
  def file_size_mb
    return 0 unless file_size
    (file_size / 1024.0 / 1024.0).round(2)
  end
  
  def processing_time_seconds
    return 0 unless started_at && completed_at
    (completed_at - started_at).round(2)
  end
  
  def rows_per_second
    return 0 unless processing_time_seconds > 0
    (processed_rows.to_f / processing_time_seconds).round(2)
  end
end
