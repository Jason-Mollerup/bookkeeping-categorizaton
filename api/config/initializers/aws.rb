# AWS S3 Configuration
Aws.config.update({
  region: Rails.application.credentials.aws.region || 'us-east-1',
  credentials: Aws::Credentials.new(
    Rails.application.credentials.aws.access_key_id,
    Rails.application.credentials.aws.secret_access_key
  )
})

# S3 Client
S3_CLIENT = Aws::S3::Client.new

# S3 Bucket
S3_BUCKET = Rails.application.credentials.aws.bucket_name || 'bookkeeping-imports'
