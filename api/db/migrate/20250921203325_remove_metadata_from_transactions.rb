class RemoveMetadataFromTransactions < ActiveRecord::Migration[8.0]
  def change
    remove_column :transactions, :metadata, :jsonb
  end
end
