class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify
  has_many :categorization_rules, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
end
