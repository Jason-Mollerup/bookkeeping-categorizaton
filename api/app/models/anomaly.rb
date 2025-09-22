class Anomaly < ApplicationRecord
  belongs_to :transaction_record, class_name: 'Transaction', foreign_key: 'transaction_id'

  validates :anomaly_type, presence: true, inclusion: { in: %w[unusual_amount duplicate missing_description suspicious_pattern] }
  validates :severity, presence: true, inclusion: { in: %w[low medium high critical] }
  validates :description, presence: true

  scope :unresolved, -> { where(resolved: false) }
  scope :by_severity, ->(severity) { where(severity: severity) }

  after_create :broadcast_anomaly_detected, unless: :skip_callbacks
  after_update :broadcast_anomaly_resolved, if: :saved_change_to_resolved?, unless: :skip_callbacks

  private

  def skip_callbacks
    Rails.env.test? || caller.any? { |line| line.include?('db/seeds.rb') }
  end

  def broadcast_anomaly_detected
    ::WebSocketService.broadcast_anomaly_detected(transaction_record.user_id, self)
  end

  def broadcast_anomaly_resolved
    if resolved?
      ::WebSocketService.broadcast_anomaly_resolved(transaction_record.user_id, id)
    end
  end
end
