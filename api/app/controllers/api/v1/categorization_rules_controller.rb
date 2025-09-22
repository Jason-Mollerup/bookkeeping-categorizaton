class Api::V1::CategorizationRulesController < Api::V1::BaseController
  before_action :set_rule, only: [:show, :update, :destroy]

  def index
    rules = current_user.categorization_rules
                       .includes(:category)
                       .order(:priority)

    render json: { rules: rules.map { |r| rule_json(r) } }
  end

  def show
    render json: { rule: rule_json(@rule) }
  end

  def create
    result = CategorizationEngine.create_rule_and_apply(current_user.id, rule_params)
    
    if result[:success]
      render json: { 
        rule: rule_json(result[:rule]),
        applied_to_existing: result[:applied_to_existing]
      }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def update
    if @rule.update(rule_params)
      # Re-apply rules to existing transactions if rule was activated
      if @rule.active? && @rule.saved_change_to_active?
        CategorizationEngine.bulk_apply_rules(current_user.id)
      end
      
      render json: { rule: rule_json(@rule) }
    else
      render json: { errors: @rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy
    head :no_content
  end

  # Bulk Operations
  def bulk_activate
    rule_ids = params[:rule_ids]

    if rule_ids.blank?
      return render_error('rule_ids are required')
    end

    updated_count = CategorizationRule.bulk_activate(rule_ids, current_user.id)
    render_success({ updated_count: updated_count }, 'Rules activated successfully')
  end

  def bulk_deactivate
    rule_ids = params[:rule_ids]

    if rule_ids.blank?
      return render_error('rule_ids are required')
    end

    updated_count = CategorizationRule.bulk_deactivate(rule_ids, current_user.id)
    render_success({ updated_count: updated_count }, 'Rules deactivated successfully')
  end

  def bulk_delete
    rule_ids = params[:rule_ids]

    if rule_ids.blank?
      return render_error('rule_ids are required')
    end

    CategorizationRule.bulk_delete(rule_ids, current_user.id)
    render_success({}, 'Rules deleted successfully')
  end

  def bulk_reorder
    rule_orders = params[:rule_orders]

    if rule_orders.blank?
      return render_error('rule_orders are required')
    end

    CategorizationRule.bulk_reorder(rule_orders, current_user.id)
    render_success({}, 'Rules reordered successfully')
  end


  private

  def set_rule
    @rule = current_user.categorization_rules.find(params[:id])
  end

  def rule_params
    params.require(:rule).permit(:name, :category_id, :priority, :active, rule_predicate: {})
  end

  def rule_json(rule)
    {
      id: rule.id,
      name: rule.name,
      rule_predicate: rule.rule_predicate,
      category_id: rule.category_id,
      category: {
        id: rule.category.id,
        name: rule.category.name,
        color: rule.category.color
      },
      priority: rule.priority,
      active: rule.active,
      created_at: rule.created_at,
      updated_at: rule.updated_at
    }
  end
end
