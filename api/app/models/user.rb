class User < ApplicationRecord
  has_secure_password
  
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :categorization_rules, dependent: :destroy
  has_many :anomalies, through: :transactions
  has_many :csv_imports, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
