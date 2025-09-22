class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_transaction, only: [:show, :update, :destroy]

  def index
    result = PerformanceMonitoringService.log_query_performance('transactions_index') do
      PaginationService.paginate_transactions(current_user.id, params)
    end

    render json: {
      data: result[:data],
      pagination: result[:pagination]
    }
  end

  def show
    render json: { transaction: transaction_json(@transaction) }
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    
    if @transaction.save
      render json: { transaction: transaction_json(@transaction) }, status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: { transaction: transaction_json(@transaction) }
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    head :no_content
  end

  # Bulk Operations
  def bulk_categorize
    transaction_ids = params[:transaction_ids]
    category_id = params[:category_id]

    if transaction_ids.blank? || category_id.blank?
      return render_error('transaction_ids and category_id are required')
    end

    result = PerformanceMonitoringService.monitor_bulk_operation('bulk_categorize') do
      BulkOperationsService.bulk_categorize_optimized(transaction_ids, category_id, current_user.id)
    end
    
    if result[:success]
      render_success({ updated_count: result[:updated_count] }, 'Transactions categorized successfully')
    else
      render_error(result[:error])
    end
  end

  def bulk_mark_reviewed
    transaction_ids = params[:transaction_ids]
    reviewed = params[:reviewed] != false

    if transaction_ids.blank?
      return render_error('transaction_ids are required')
    end

    result = Transaction.bulk_mark_reviewed(transaction_ids, current_user.id, reviewed: reviewed)
    render_success({ 
      deleted_anomalies: result[:deleted_anomalies], 
      transaction_count: result[:transaction_count] 
    }, "Deleted #{result[:deleted_anomalies]} anomalies from #{result[:transaction_count]} transactions")
  end

  def bulk_delete
    transaction_ids = params[:transaction_ids]

    if transaction_ids.blank?
      return render_error('transaction_ids are required')
    end

    Transaction.bulk_delete(transaction_ids, current_user.id)
    render_success({}, 'Transactions deleted successfully')
  end

  def bulk_apply_rules
    transaction_ids = params[:transaction_ids]

    Transaction.bulk_apply_rules(current_user.id, transaction_ids)
    render_success({}, 'Rules application started - you will be notified when complete')
  end

  def bulk_detect_anomalies
    transaction_ids = params[:transaction_ids]

    result = Transaction.bulk_detect_anomalies(current_user.id, transaction_ids)
    
    if result[:success]
      render_success({ detected_count: result[:detected_count] }, 'Anomaly detection completed')
    else
      render_error(result[:error])
    end
  end

  def apply_rules
    @transaction.apply_rules_manually
    render json: { 
      transaction: transaction_json(@transaction),
      message: 'Categorization rules applied successfully'
    }
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:amount, :description, :date, :category_id)
  end

  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      category_id: transaction.category_id,
      category: transaction.category ? {
        id: transaction.category.id,
        name: transaction.category.name,
        color: transaction.category.color
      } : nil,
      anomalies: transaction.anomalies.unresolved.map { |a| {
        id: a.id,
        type: a.anomaly_type,
        severity: a.severity,
        description: a.description
      }},
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    }
  end
end
