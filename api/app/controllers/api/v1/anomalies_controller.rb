class Api::V1::AnomaliesController < Api::V1::BaseController
  before_action :set_anomaly, only: [:show, :resolve]

  def index
    anomalies = current_user.anomalies
                           .includes(transaction_record: :category)
                           .unresolved
                           .order(created_at: :desc)

    # Filtering
    anomalies = anomalies.by_severity(params[:severity]) if params[:severity]
    anomalies = anomalies.where(anomaly_type: params[:type]) if params[:type]

    # Pagination
    page = params[:page] || 1
    per_page = [params[:per_page]&.to_i || 25, 100].min
    anomalies = anomalies.page(page).per(per_page)

    render json: {
      data: anomalies.map { |a| anomaly_json(a) },
      pagination: {
        current_page: anomalies.current_page,
        total_pages: anomalies.total_pages,
        total_count: anomalies.total_count,
        per_page: per_page
      }
    }
  end

  def show
    render json: { anomaly: anomaly_json(@anomaly) }
  end

  def resolve
    if @anomaly.update(resolved: true)
      render json: { anomaly: anomaly_json(@anomaly) }
    else
      render json: { errors: @anomaly.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def bulk_resolve
    anomaly_ids = params[:anomaly_ids]

    if anomaly_ids.blank?
      return render_error('anomaly_ids are required')
    end

    result = AnomalyDetectionService.resolve_anomalies(anomaly_ids, current_user.id)
    
    if result[:success]
      render_success({ resolved_count: result[:resolved_count] }, 'Anomalies resolved successfully')
    else
      render_error(result[:error])
    end
  end

  def stats
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

    render json: { stats: stats }
  end

  private

  def set_anomaly
    @anomaly = current_user.anomalies.find(params[:id])
  end

  def anomaly_json(anomaly)
    {
      id: anomaly.id,
      type: anomaly.anomaly_type,
      severity: anomaly.severity,
      description: anomaly.description,
      resolved: anomaly.resolved,
      transaction: {
        id: anomaly.transaction_record.id,
        amount: anomaly.transaction_record.amount,
        description: anomaly.transaction_record.description,
        date: anomaly.transaction_record.date
      },
      created_at: anomaly.created_at,
      updated_at: anomaly.updated_at
    }
  end
end
