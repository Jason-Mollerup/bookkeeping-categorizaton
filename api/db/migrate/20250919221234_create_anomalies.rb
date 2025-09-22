class CreateAnomalies < ActiveRecord::Migration[8.0]
  def change
    create_table :anomalies do |t|
      t.references :transaction, null: false, foreign_key: true
      t.string :anomaly_type
      t.string :severity
      t.text :description
      t.boolean :resolved

      t.timestamps
    end
  end
end
