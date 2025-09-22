class PaginationService
  DEFAULT_PAGE_SIZE = 50
  MAX_PAGE_SIZE = 1000

  def self.paginate_transactions(user_id, params = {})
    page = [params[:page]&.to_i || 1, 1].max
    per_page = [[params[:per_page]&.to_i || DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE].min, 1].max
    
    # Build base query with includes to avoid N+1
    query = Transaction.where(user_id: user_id)
                      .includes(:category)
                      .includes(anomalies: :transaction_record)
                      .order(created_at: :desc)

    # Apply filters
    query = apply_transaction_filters(query, params)

    # Get total count efficiently
    total_count = query.count

    # Calculate pagination
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page

    # Get paginated results
    transactions = query.limit(per_page).offset(offset)

    {
      data: transactions.map { |t| transaction_json(t) },
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
    }
  end

  def self.paginate_anomalies(user_id, params = {})
    page = [params[:page]&.to_i || 1, 1].max
    per_page = [[params[:per_page]&.to_i || DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE].min, 1].max
    
    # Build base query
    query = Anomaly.joins(:transaction_record)
                   .where(transactions: { user_id: user_id })
                   .includes(transaction_record: :category)
                   .unresolved
                   .order(created_at: :desc)

    # Apply filters
    query = apply_anomaly_filters(query, params)

    # Get total count
    total_count = query.count

    # Calculate pagination
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page

    # Get paginated results
    anomalies = query.limit(per_page).offset(offset)

    {
      data: anomalies.map { |a| anomaly_json(a) },
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
    }
  end

  def self.paginate(collection, page = 1, per_page = DEFAULT_PAGE_SIZE)
    page = [page&.to_i || 1, 1].max
    per_page = [[per_page&.to_i || DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE].min, 1].max
    
    # Get total count
    total_count = collection.count
    
    # Calculate pagination
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page
    
    # Get paginated results
    results = collection.limit(per_page).offset(offset)
    
    {
      data: results,
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
    }
  end

  def self.pagination_meta(paginated_result)
    paginated_result[:pagination]
  end

  def self.paginate_with_cursor(collection, cursor = nil, limit = DEFAULT_PAGE_SIZE)
    # Cursor-based pagination for better performance with large datasets
    limit = [limit, MAX_PAGE_SIZE].min
    
    query = collection.order(created_at: :desc)
    
    if cursor.present?
      cursor_time = Time.parse(cursor) rescue Time.current
      query = query.where('created_at < ?', cursor_time)
    end

    results = query.limit(limit + 1) # Get one extra to check if there are more
    has_more = results.count > limit
    
    if has_more
      results = results.limit(limit)
    end

    next_cursor = has_more ? results.last.created_at.iso8601 : nil

    {
      data: results,
      pagination: {
        has_more: has_more,
        next_cursor: next_cursor,
        limit: limit
      }
    }
  end

  private

  def self.apply_transaction_filters(query, params)
    query = query.where(category_id: params[:category_id]) if params[:category_id]
    query = query.uncategorized if params[:uncategorized] == true || params[:uncategorized] == 'true'
    query = query.uncategorized if params[:anomaly_type] == 'uncategorized'
    query = query.uncategorized if params[:anomaly_types]&.include?('uncategorized')

    puts "params[:anomaly_types]: #{params[:anomaly_types]}"

    # remove uncategorized from anomaly_types
    params[:anomaly_types] = params[:anomaly_types]&.reject { |type| type == 'uncategorized' }
    
    # Handle both single anomaly_type and array of anomaly_types for backward compatibility
    if params[:anomaly_type].present?
      query = query.joins(:anomalies).where(anomalies: { anomaly_type: params[:anomaly_type] })
    elsif params[:anomaly_types].present? && params[:anomaly_types].is_a?(Array)
      query = query.joins(:anomalies).where(anomalies: { anomaly_type: params[:anomaly_types] })
    end
    
    # Add search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      query = query.where(
        "description ILIKE ? OR amount::text ILIKE ?",
        search_term, search_term
      )
    end
    
    if params[:start_date] && params[:end_date]
      query = query.by_date_range(
        Date.parse(params[:start_date]),
        Date.parse(params[:end_date])
      )
    end

    query
  end

  def self.apply_anomaly_filters(query, params)
    query = query.by_severity(params[:severity]) if params[:severity]
    query = query.where(anomaly_type: params[:type]) if params[:type]
    query
  end

  def self.transaction_json(transaction)
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
      anomalies: transaction.anomalies.select { |a| !a.resolved }.map { |a| {
        id: a.id,
        type: a.anomaly_type,
        severity: a.severity,
        description: a.description
      }},
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    }
  end

  def self.anomaly_json(anomaly)
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
        date: anomaly.transaction_record.date,
        category: anomaly.transaction_record.category&.name
      },
      created_at: anomaly.created_at,
      updated_at: anomaly.updated_at
    }
  end
end
