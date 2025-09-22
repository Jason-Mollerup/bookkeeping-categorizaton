class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Additional indexes for bulk operations and common queries
    
    # Transaction indexes for bulk operations
    add_index :transactions, [:user_id, :flagged, :reviewed], name: 'idx_transactions_user_flagged_reviewed'
    add_index :transactions, [:user_id, :created_at], name: 'idx_transactions_user_created_at'
    add_index :transactions, [:category_id, :date], name: 'idx_transactions_category_date'
    
    # Anomaly indexes for efficient querying
    add_index :anomalies, [:transaction_id, :resolved], name: 'idx_anomalies_transaction_resolved'
    add_index :anomalies, [:anomaly_type, :severity], name: 'idx_anomalies_type_severity'
    
    # Categorization rule indexes
    add_index :categorization_rules, [:active, :priority], name: 'idx_rules_active_priority'
    
    # Category indexes
    add_index :categories, [:user_id, :name], name: 'idx_categories_user_name'
    
    # Composite indexes for dashboard queries
    add_index :transactions, [:user_id, :date, :amount], name: 'idx_transactions_user_date_amount'
    add_index :transactions, [:user_id, :category_id, :date], name: 'idx_transactions_user_category_date'
    
    # Indexes for anomaly detection performance
    add_index :transactions, [:user_id, :amount, :date], name: 'idx_transactions_user_amount_date'
    add_index :transactions, [:amount, :date], name: 'idx_transactions_amount_date'
    
    # Partial indexes for common filtered queries
    add_index :transactions, [:user_id], where: "category_id IS NULL", name: 'idx_transactions_user_uncategorized'
    add_index :transactions, [:user_id], where: "flagged = true", name: 'idx_transactions_user_flagged'
    add_index :transactions, [:user_id], where: "reviewed = false", name: 'idx_transactions_user_unreviewed'
  end
end