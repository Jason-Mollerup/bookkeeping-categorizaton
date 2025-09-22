class Api::V1::CsvImportsController < Api::V1::BaseController
  before_action :set_csv_import, only: [:show, :destroy, :progress]
  
  # GET /api/v1/csv_imports
  def index
    csv_imports = current_user.csv_imports.recent
    paginated_result = PaginationService.paginate(csv_imports, params[:page], params[:per_page])
    
    render json: {
      csv_imports: paginated_result[:data].map { |import| csv_import_json(import) },
      pagination: paginated_result[:pagination]
    }
  end
  
  # GET /api/v1/csv_imports/:id
  def show
    render json: { csv_import: csv_import_json(@csv_import) }
  end
  
  # POST /api/v1/csv_imports
  def create
    if params[:file].present?
      # Direct file upload (fallback)
      result = OptimizedCsvImportService.new(
        user: current_user,
        file: params[:file],
        filename: params[:file].original_filename
      ).create_import
    elsif params[:s3_key].present?
      # S3 upload (preferred method)
      result = OptimizedCsvImportService.new(
        user: current_user,
        s3_key: params[:s3_key],
        filename: params[:filename]
      ).create_import
    else
      result = { success: false, errors: ['No file provided'] }
    end
    
    if result[:success]
      render json: { 
        csv_import: csv_import_json(result[:csv_import]),
        message: 'CSV import started successfully'
      }, status: :created
    else
      render json: { 
        errors: result[:errors] 
      }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/csv_imports/presigned_url
  def presigned_url
    filename = params[:filename]
    content_type = params[:content_type] || 'text/csv'
    
    if filename.blank?
      render json: { error: 'Filename is required' }, status: :bad_request
      return
    end
    
    result = OptimizedCsvImportService.generate_presigned_url(
      current_user, 
      filename, 
      content_type
    )
    
    render json: result
  end
  
  # DELETE /api/v1/csv_imports/:id
  def destroy
    if @csv_import.processing?
      render json: { error: 'Cannot delete import while processing' }, 
             status: :unprocessable_entity
      return
    end
    
    @csv_import.destroy
    head :no_content
  end
  
  # GET /api/v1/csv_imports/:id/progress
  def progress
    render json: { csv_import: csv_import_json(@csv_import) }
  end
  
  private
  
  def set_csv_import
    @csv_import = current_user.csv_imports.find(params[:id])
  end
  
  def csv_import_json(csv_import)
    {
      id: csv_import.id,
      filename: csv_import.filename,
      status: csv_import.status,
      progress_percentage: csv_import.progress_percentage,
      total_rows: csv_import.total_rows,
      processed_rows: csv_import.processed_rows,
      error_rows: csv_import.error_rows,
      file_size_mb: csv_import.file_size_mb,
      processing_time_seconds: csv_import.processing_time_seconds,
      rows_per_second: csv_import.rows_per_second,
      started_at: csv_import.started_at,
      completed_at: csv_import.completed_at,
      error_message: csv_import.error_message,
      metadata: csv_import.metadata,
      created_at: csv_import.created_at,
      updated_at: csv_import.updated_at
    }
  end
end
