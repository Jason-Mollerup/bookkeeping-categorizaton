require_relative '../application_cable/connection'
require_relative '../application_cable/channel'

class AnomalyChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    
    stream_from "user_#{current_user.id}_anomalies"
    
    anomaly_count = current_user.anomalies.unresolved.count
    transmit({
      type: 'anomaly_count_update',
      count: anomaly_count,
      timestamp: Time.current
    })
  end

  def unsubscribed; end

  def mark_resolved(data)
    return reject unless current_user
    
    anomaly_id = data['anomaly_id']
    return reject unless anomaly_id

    anomaly = current_user.anomalies.find(anomaly_id)
    if anomaly&.update(resolved: true)
      broadcast_to_user({
        type: 'anomaly_resolved',
        anomaly_id: anomaly_id,
        remaining_count: current_user.anomalies.unresolved.count
      })
    else
      transmit({
        type: 'error',
        message: 'Failed to resolve anomaly'
      })
    end
  end

  def bulk_resolve(data)
    return reject unless current_user
    
    anomaly_ids = data['anomaly_ids']
    return reject unless anomaly_ids.is_a?(Array)

    result = AnomalyDetectionService.resolve_anomalies(anomaly_ids, current_user.id)
    
    if result[:success]
      broadcast_to_user({
        type: 'anomalies_bulk_resolved',
        resolved_count: result[:resolved_count],
        remaining_count: current_user.anomalies.unresolved.count
      })
    else
      transmit({
        type: 'error',
        message: result[:error]
      })
    end
  end

  def get_stats
    return reject unless current_user
    
    stats = {
      total_unresolved: current_user.anomalies.unresolved.count,
      by_severity: {
        critical: current_user.anomalies.unresolved.by_severity('critical').count,
        high: current_user.anomalies.unresolved.by_severity('high').count,
        medium: current_user.anomalies.unresolved.by_severity('medium').count,
        low: current_user.anomalies.unresolved.by_severity('low').count
      },
      by_type: {
        unusual_amount: current_user.anomalies.unresolved.where(anomaly_type: 'unusual_amount').count,
        duplicate: current_user.anomalies.unresolved.where(anomaly_type: 'duplicate').count,
        missing_description: current_user.anomalies.unresolved.where(anomaly_type: 'missing_description').count,
        suspicious_pattern: current_user.anomalies.unresolved.where(anomaly_type: 'suspicious_pattern').count
      }
    }

    transmit({
      type: 'anomaly_stats',
      stats: stats,
      timestamp: Time.current
    })
  end


  def broadcast_to_user(data)
    ActionCable.server.broadcast("user_#{current_user.id}_anomalies", data)
  end
end
