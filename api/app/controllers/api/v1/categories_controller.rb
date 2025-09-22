class Api::V1::CategoriesController < Api::V1::BaseController
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    categories = current_user.categories.order(:name)
    render json: { categories: categories.map { |c| category_json(c) } }
  end

  def show
    render json: { category: category_json(@category) }
  end

  def create
    @category = current_user.categories.build(category_params)
    
    if @category.save
      render json: { category: category_json(@category) }, status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: { category: category_json(@category) }
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.transactions.exists?
      return render_error('Cannot delete category with existing transactions')
    end

    @category.destroy
    head :no_content
  end

  def stats
    category = current_user.categories.find(params[:id])
    
    stats = {
      total_transactions: category.transactions.count,
      total_amount: category.transactions.sum(:amount),
      average_amount: category.transactions.average(:amount),
      this_month: category.transactions.where(date: Date.current.beginning_of_month..Date.current.end_of_month).count,
      last_month: category.transactions.where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).count
    }

    render json: { category: category_json(category), stats: stats }
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end

  def category_json(category)
    {
      id: category.id,
      name: category.name,
      color: category.color,
      transaction_count: category.transactions.count,
      created_at: category.created_at,
      updated_at: category.updated_at
    }
  end
end
