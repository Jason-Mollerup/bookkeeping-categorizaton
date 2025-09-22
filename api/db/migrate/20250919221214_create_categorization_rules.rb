class CreateCategorizationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :categorization_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :condition_type
      t.string :condition_value
      t.references :category, null: false, foreign_key: true
      t.integer :priority
      t.boolean :active

      t.timestamps
    end

    add_index :categorization_rules, [:user_id, :active]
  end
end
