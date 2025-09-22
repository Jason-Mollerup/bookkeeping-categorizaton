class RemoveReviewedAndFlaggedFromTransactions < ActiveRecord::Migration[8.0]
  def change
    remove_column :transactions, :reviewed, :boolean
    remove_column :transactions, :flagged, :boolean
  end
end
