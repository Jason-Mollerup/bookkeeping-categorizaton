class CreateCsvImports < ActiveRecord::Migration[8.0]
  def change
    create_table :csv_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :status, null: false, default: 'pending'
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :error_rows, null: false, default: 0
      t.bigint :file_size
      t.string :s3_key
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :csv_imports, [:user_id, :status]
    add_index :csv_imports, [:user_id, :created_at]
    add_index :csv_imports, :status
    add_index :csv_imports, :s3_key, unique: true
  end
end
