class UpdateCategorizationRulesToUseJson < ActiveRecord::Migration[8.0]
  def up
    # Add new JSON column for rule predicates
    add_column :categorization_rules, :rule_predicate, :jsonb, null: false, default: {}
    
    # Migrate existing data to new format
    CategorizationRule.find_each do |rule|
      predicate = case rule.condition_type
      when "contains"
        {
          type: "STRING",
          column: "description",
          operator: "CONTAINS",
          operand: rule.condition_value
        }
      when "amount_greater_than"
        {
          type: "NUMBER",
          column: "amount",
          operator: "GREATER_THAN",
          operand: rule.condition_value.to_f
        }
      when "amount_less_than"
        {
          type: "NUMBER",
          column: "amount",
          operator: "LESS_THAN",
          operand: rule.condition_value.to_f
        }
      when "amount_between"
        min, max = rule.condition_value.split(",").map(&:to_f)
        {
          type: "COMPOUND",
          operator: "AND",
          predicates: [
            {
              type: "NUMBER",
              column: "amount",
              operator: "GREATER_THAN_OR_EQUAL",
              operand: min
            },
            {
              type: "NUMBER",
              column: "amount",
              operator: "LESS_THAN_OR_EQUAL",
              operand: max
            }
          ]
        }
      when "description_matches"
        {
          type: "STRING",
          column: "description",
          operator: "MATCHES",
          operand: rule.condition_value
        }
      when "date_after"
        {
          type: "DATE",
          column: "date",
          operator: "AFTER",
          operand: rule.condition_value
        }
      when "date_before"
        {
          type: "DATE",
          column: "date",
          operator: "BEFORE",
          operand: rule.condition_value
        }
      when "day_of_week"
        {
          type: "DATE",
          column: "date",
          operator: "DAY_OF_WEEK",
          operand: rule.condition_value.downcase
        }
      else
        {
          type: "STRING",
          column: "description",
          operator: "CONTAINS",
          operand: rule.condition_value
        }
      end
      
      rule.update!(rule_predicate: predicate)
    end
    
    # Remove old columns
    remove_column :categorization_rules, :condition_type
    remove_column :categorization_rules, :condition_value
  end

  def down
    # Add back old columns
    add_column :categorization_rules, :condition_type, :string
    add_column :categorization_rules, :condition_value, :string
    
    # Migrate data back (simplified - only handles simple predicates)
    CategorizationRule.find_each do |rule|
      predicate = rule.rule_predicate
      
      if predicate["type"] == "COMPOUND"
        # Skip complex rules in rollback
        next
      end
      
      case predicate["type"]
      when "STRING"
        if predicate["operator"] == "CONTAINS"
          rule.update!(
            condition_type: "contains",
            condition_value: predicate["operand"]
          )
        elsif predicate["operator"] == "MATCHES"
          rule.update!(
            condition_type: "description_matches",
            condition_value: predicate["operand"]
          )
        end
      when "NUMBER"
        if predicate["operator"] == "GREATER_THAN"
          rule.update!(
            condition_type: "amount_greater_than",
            condition_value: predicate["operand"].to_s
          )
        elsif predicate["operator"] == "LESS_THAN"
          rule.update!(
            condition_type: "amount_less_than",
            condition_value: predicate["operand"].to_s
          )
        end
      when "DATE"
        if predicate["operator"] == "AFTER"
          rule.update!(
            condition_type: "date_after",
            condition_value: predicate["operand"]
          )
        elsif predicate["operator"] == "BEFORE"
          rule.update!(
            condition_type: "date_before",
            condition_value: predicate["operand"]
          )
        elsif predicate["operator"] == "DAY_OF_WEEK"
          rule.update!(
            condition_type: "day_of_week",
            condition_value: predicate["operand"]
          )
        end
      end
    end
    
    # Remove new column
    remove_column :categorization_rules, :rule_predicate
  end
end