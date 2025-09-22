class Api::V1::JobQueueController < Api::V1::BaseController
  # GET /api/v1/job_queue/status
  def status
    begin
      # Get queue statistics from SolidQueue
      queue_stats = {}
      
      # Check each queue for pending and running jobs
      %w[import_processing post_processing low_priority default].each do |queue_name|
        queue_stats[queue_name] = {
          pending: SolidQueue::Job.where(queue_name: queue_name, finished_at: nil).count,
          running: SolidQueue::Job.where(queue_name: queue_name, finished_at: nil).where.not(started_at: nil).count,
          failed: SolidQueue::Job.where(queue_name: queue_name, finished_at: nil, failed_at: nil).count
        }
      end
      
      # Get overall system health
      total_pending = queue_stats.values.sum { |stats| stats[:pending] }
      total_running = queue_stats.values.sum { |stats| stats[:running] }
      total_failed = queue_stats.values.sum { |stats| stats[:failed] }
      
      render json: {
        status: 'healthy',
        queues: queue_stats,
        summary: {
          total_pending: total_pending,
          total_running: total_running,
          total_failed: total_failed,
          health_status: total_failed > 10 ? 'degraded' : 'healthy'
        },
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        error: e.message,
        timestamp: Time.current
      }, status: :internal_server_error
    end
  end
  
  # GET /api/v1/job_queue/workers
  def workers
    begin
      # Get worker information
      worker_stats = {
        total_workers: ENV.fetch("IMPORT_WORKERS", 2).to_i + 
                      ENV.fetch("POST_PROCESSING_WORKERS", 2).to_i + 
                      ENV.fetch("LOW_PRIORITY_WORKERS", 1).to_i + 
                      ENV.fetch("DEFAULT_WORKERS", 1).to_i,
        import_workers: ENV.fetch("IMPORT_WORKERS", 2).to_i,
        post_processing_workers: ENV.fetch("POST_PROCESSING_WORKERS", 2).to_i,
        low_priority_workers: ENV.fetch("LOW_PRIORITY_WORKERS", 1).to_i,
        default_workers: ENV.fetch("DEFAULT_WORKERS", 1).to_i
      }
      
      render json: {
        workers: worker_stats,
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        error: e.message,
        timestamp: Time.current
      }, status: :internal_server_error
    end
  end
end
