class PerformanceMonitoringService
  def self.log_query_performance(query_name, &block)
    start_time = Time.current
    result = yield
    execution_time = Time.current - start_time
    
    if execution_time > 1.0 # Log slow queries
      Rails.logger.warn "Slow query detected: #{query_name} took #{execution_time.round(3)}s"
    end
    
    result
  end

  def self.log_memory_usage(operation_name)
    start_memory = get_memory_usage
    
    result = yield
    
    end_memory = get_memory_usage
    memory_delta = end_memory - start_memory
    
    if memory_delta > 100.megabytes # Log high memory usage
      Rails.logger.warn "High memory usage: #{operation_name} used #{memory_delta / 1.megabyte}MB"
    end
    
    result
  end

  def self.cleanup_websocket_connections
    # Clean up stale WebSocket connections
    # This would typically be called by a scheduled job
    
    stale_connections = ActionCable.server.connections.select do |connection|
      # Check if connection is stale (no activity for 30 minutes)
      connection.last_activity_at < 30.minutes.ago
    end
    
    stale_connections.each do |connection|
      connection.close
    end
    
    Rails.logger.info "Cleaned up #{stale_connections.count} stale WebSocket connections"
  end

  def self.monitor_bulk_operation(operation_name, &block)
    start_time = Time.current
    start_memory = get_memory_usage
    
    result = yield
    
    execution_time = Time.current - start_time
    memory_used = get_memory_usage - start_memory
    
    Rails.logger.info "Bulk operation #{operation_name}: #{execution_time.round(3)}s, #{memory_used / 1.megabyte}MB"
    
    result
  end

  def self.get_database_stats
    {
      transaction_count: Transaction.count,
      anomaly_count: Anomaly.count,
      user_count: User.count,
      category_count: Category.count,
      rule_count: CategorizationRule.count
    }
  end

  def self.get_cache_stats
    {
      cache_hits: Rails.cache.stats[:hits] || 0,
      cache_misses: Rails.cache.stats[:misses] || 0,
      cache_size: Rails.cache.stats[:size] || 0
    }
  end

  def self.get_websocket_stats
    {
      active_connections: ActionCable.server.connections.count,
      channels: ActionCable.server.connections.map(&:subscriptions).flatten.count
    }
  end

  def self.get_performance_summary
    {
      database: get_database_stats,
      cache: get_cache_stats,
      websockets: get_websocket_stats,
      timestamp: Time.current
    }
  end

  private

  def self.get_memory_usage
    # Get memory usage in bytes
    `ps -o rss= -p #{Process.pid}`.to_i * 1024
  rescue
    0
  end
end
