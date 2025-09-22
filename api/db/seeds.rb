# Helper methods for generating realistic data
def generate_description(template, pattern_data)
  description = template.dup
  
  # Replace placeholders with random values
  description.gsub!(/\{store\}/, pattern_data[:stores]&.sample || "Store")
  description.gsub!(/\{restaurant\}/, pattern_data[:restaurants]&.sample || "Restaurant")
  description.gsub!(/\{coffee_shop\}/, pattern_data[:coffee_shops]&.sample || "Coffee Shop")
  description.gsub!(/\{delivery_service\}/, pattern_data[:delivery_services]&.sample || "Delivery")
  description.gsub!(/\{cafe\}/, pattern_data[:cafes]&.sample || "Cafe")
  description.gsub!(/\{convenience_store\}/, pattern_data[:convenience_stores]&.sample || "Store")
  description.gsub!(/\{item\}/, pattern_data[:items]&.sample || "item")
  description.gsub!(/\{station\}/, pattern_data[:stations]&.sample || "Station")
  description.gsub!(/\{destination\}/, pattern_data[:destinations]&.sample || "destination")
  description.gsub!(/\{location\}/, pattern_data[:locations]&.sample || "location")
  description.gsub!(/\{theater\}/, pattern_data[:theaters]&.sample || "Theater")
  description.gsub!(/\{game\}/, pattern_data[:games]&.sample || "Game")
  description.gsub!(/\{service\}/, pattern_data[:services]&.sample || "Service")
  description.gsub!(/\{month\}/, pattern_data[:months]&.sample || "Month")
  description.gsub!(/\{provider\}/, pattern_data[:providers]&.sample || "Provider")
  description.gsub!(/\{carrier\}/, pattern_data[:carriers]&.sample || "Carrier")
  description.gsub!(/\{type\}/, pattern_data[:types]&.sample || "Type")
  description.gsub!(/\{specialty\}/, pattern_data[:specialties]&.sample || "Specialty")
  description.gsub!(/\{medication\}/, pattern_data[:medications]&.sample || "Medication")
  description.gsub!(/\{airline\}/, pattern_data[:airlines]&.sample || "Airline")
  description.gsub!(/\{company\}/, pattern_data[:companies]&.sample || "Company")
  description.gsub!(/\{client\}/, pattern_data[:clients]&.sample || "Client")
  description.gsub!(/\{source\}/, pattern_data[:sources]&.sample || "Source")
  
  # Add some variation
  if rand < 0.3  # 30% chance to add variation
    variations = [
      " - Mobile App",
      " - Online Order",
      " - Store ##{rand(100..999)}",
      " - Location #{rand(1..50)}",
      " - Transaction ##{rand(1000..9999)}",
      " - #{Date.current.strftime('%m/%d/%Y')}"
    ]
    description += variations.sample
  end
  
  description
end

def generate_amount(range, category_name)
  base_amount = rand(range[0]..range[1])
  
  # Add realistic pricing patterns
  case category_name
  when "Food & Dining"
    # Often ends in .99, .95, .49
    endings = [0.99, 0.95, 0.49, 0.00, 0.50]
    base_amount = base_amount.floor + endings.sample
  when "Transportation"
    # Gas often has 3 decimal places
    if rand < 0.3
      base_amount = (base_amount * 1000).round / 1000.0
    end
  when "Bills & Utilities"
    # Often round numbers
    base_amount = base_amount.round
  when "Shopping"
    # Often ends in .99
    if rand < 0.6
      base_amount = base_amount.floor + 0.99
    end
  end
  
  # Income is positive, expenses are negative
  if category_name == "Income"
    base_amount.abs
  else
    -base_amount.abs
  end
end

def generate_random_date(start_date, end_date)
  # Weight recent dates more heavily (more recent transactions)
  days_diff = (end_date - start_date).to_i
  recent_weight = days_diff / 3  # Last third of time period gets more weight
  
  if rand < 0.7  # 70% chance for recent dates
    random_days = rand(0..recent_weight)
  else
    random_days = rand(0..days_diff)
  end
  
  start_date + random_days
end

def generate_questionable_amount(original_amount, category_name)
  # Generate questionable amounts that would trigger anomaly detection
  questionable_patterns = [
    # Extremely high amounts
    original_amount * rand(50..200),
    
    # Suspiciously round amounts for non-bill categories
    case category_name
    when "Food & Dining", "Transportation", "Shopping", "Entertainment"
      # Round amounts are suspicious for these categories
      rand(100..5000).to_i * 100  # $100, $200, $300, etc.
    else
      original_amount * rand(50..200)
    end,
    
    # Negative amounts for income categories (should be positive)
    if category_name == "Income"
      -rand(1000..10000).abs
    else
      original_amount * rand(50..200)
    end,
    
    # Positive amounts for expense categories (should be negative)
    if category_name != "Income"
      rand(100..5000).abs
    else
      original_amount * rand(50..200)
    end,
    
    # Suspiciously low amounts for high-value categories
    case category_name
    when "Travel", "Healthcare", "Bills & Utilities"
      rand(0.01..5.00)  # Very low for these categories
    else
      original_amount * rand(50..200)
    end,
    
    # Suspiciously high amounts for low-value categories
    case category_name
    when "Food & Dining", "Transportation"
      rand(1000..50000)  # Very high for these categories
    else
      original_amount * rand(50..200)
    end
  ]
  
  questionable_patterns.sample
end


# Clear existing data
puts "Clearing existing data..."
Anomaly.delete_all
CategorizationRule.delete_all
Transaction.delete_all
Category.delete_all
CsvImport.delete_all
User.delete_all

puts "Creating users..."

# Create test users
users = [
  {
    email: "demo@bookkeeping.com",
    password: "demo1234",
    password_confirmation: "demo1234"
  }
]

created_users = users.map do |user_data|
  User.create!(user_data)
end

puts "Created #{created_users.length} users"

# Create categories for each user
puts "Creating categories..."

category_templates = [
  { name: "Food & Dining", color: "#FF6B6B" },
  { name: "Transportation", color: "#4ECDC4" },
  { name: "Shopping", color: "#45B7D1" },
  { name: "Entertainment", color: "#96CEB4" },
  { name: "Bills & Utilities", color: "#FFEAA7" },
  { name: "Healthcare", color: "#DDA0DD" },
  { name: "Travel", color: "#98D8C8" },
  { name: "Education", color: "#F7DC6F" },
  { name: "Income", color: "#82E0AA" },
  { name: "Savings", color: "#85C1E9" },
  { name: "Miscellaneous", color: "#F8C471" }
]

all_categories = []

created_users.each do |user|
  user_categories = category_templates.map do |template|
    Category.create!(
      user: user,
      name: template[:name],
      color: template[:color]
    )
  end
  all_categories.concat(user_categories)
end

puts "Created #{all_categories.length} categories"

# Create massive transaction dataset
puts "Creating large transaction dataset..."

# Configuration for data generation
TOTAL_TRANSACTIONS = 50_000  # 500k transactions per user
START_DATE = 5.years.ago.to_date
END_DATE = Date.current
BATCH_SIZE = 10_000  # Process in batches for memory efficiency

# Transaction patterns with realistic templates
transaction_patterns = {
  "Food & Dining" => {
    templates: [
      "Grocery shopping at {store}",
      "Lunch at {restaurant}",
      "Coffee at {coffee_shop}",
      "Dinner at {restaurant}",
      "{delivery_service} delivery",
      "Breakfast at {cafe}",
      "Takeout from {restaurant}",
      "Snacks at {convenience_store}"
    ],
    stores: ["Whole Foods", "Safeway", "Kroger", "Trader Joe's", "Costco", "Walmart", "Target"],
    restaurants: ["McDonald's", "Subway", "Chipotle", "Panera", "Taco Bell", "Pizza Hut", "Domino's"],
    coffee_shops: ["Starbucks", "Dunkin'", "Peet's Coffee", "Caribou Coffee", "Local Coffee Co."],
    delivery_services: ["Uber Eats", "DoorDash", "Grubhub", "Postmates"],
    cafes: ["Corner Cafe", "Morning Brew", "Coffee Bean"],
    convenience_stores: ["7-Eleven", "Circle K", "Shell", "BP"],
    amount_range: [3.50, 85.00],
    frequency: 0.25
  },
  
  "Transportation" => {
    templates: [
      "Gas at {station}",
      "Uber ride to {destination}",
      "Lyft to {destination}",
      "Metro card reload",
      "Parking at {location}",
      "Toll road payment"
    ],
    stations: ["Shell", "Exxon", "BP", "Chevron", "Circle K"],
    destinations: ["airport", "downtown", "office", "mall", "hospital"],
    locations: ["downtown", "mall", "airport", "hospital"],
    amount_range: [2.50, 85.00],
    frequency: 0.15
  },
  
  "Shopping" => {
    templates: [
      "Amazon purchase - {item}",
      "Target - {item}",
      "Walmart - {item}",
      "Best Buy - {item}",
      "Online order from {store}"
    ],
    items: ["electronics", "clothing", "home goods", "books", "toys"],
    stores: ["Amazon", "Target", "Walmart", "Best Buy", "Home Depot"],
    amount_range: [12.99, 899.99],
    frequency: 0.20
  },
  
  "Entertainment" => {
    templates: [
      "Netflix subscription",
      "Spotify Premium",
      "Movie tickets at {theater}",
      "Video game - {game}",
      "Streaming service - {service}"
    ],
    theaters: ["AMC", "Regal", "Cinemark", "Alamo Drafthouse"],
    games: ["Call of Duty", "FIFA", "Minecraft", "Fortnite"],
    services: ["Hulu", "Disney+", "HBO Max", "Prime Video"],
    amount_range: [9.99, 299.99],
    frequency: 0.08
  },
  
  "Bills & Utilities" => {
    templates: [
      "Electric bill - {month}",
      "Internet service - {provider}",
      "Phone bill - {carrier}",
      "Water bill - {month}",
      "Insurance payment - {type}"
    ],
    months: ["January", "February", "March", "April", "May", "June"],
    providers: ["Comcast", "Verizon", "AT&T", "Spectrum"],
    carriers: ["Verizon", "AT&T", "T-Mobile", "Sprint"],
    types: ["auto", "home", "health", "life"],
    amount_range: [45.00, 2500.00],
    frequency: 0.12
  },
  
  "Healthcare" => {
    templates: [
      "Doctor visit - {specialty}",
      "Pharmacy - {medication}",
      "Dental cleaning",
      "Eye exam",
      "Prescription - {medication}"
    ],
    specialties: ["general", "dermatology", "cardiology", "orthopedics"],
    medications: ["antibiotics", "pain relief", "vitamins", "prescription"],
    amount_range: [25.00, 850.00],
    frequency: 0.06
  },
  
  "Travel" => {
    templates: [
      "Hotel booking - {location}",
      "Flight tickets - {airline}",
      "Rental car - {company}",
      "Airbnb - {location}"
    ],
    locations: ["New York", "Los Angeles", "Chicago", "Miami", "Seattle"],
    airlines: ["American", "Delta", "United", "Southwest"],
    companies: ["Hertz", "Enterprise", "Avis", "Budget"],
    amount_range: [150.00, 3500.00],
    frequency: 0.04
  },
  
  "Income" => {
    templates: [
      "Salary deposit - {company}",
      "Freelance payment - {client}",
      "Investment dividend",
      "Bonus payment",
      "Refund - {source}"
    ],
    companies: ["Tech Corp", "Consulting Inc", "Local Business"],
    clients: ["Client A", "Client B", "Small Business"],
    sources: ["Amazon", "Target", "Restaurant"],
    amount_range: [25.00, 8500.00],
    frequency: 0.08
  },
  
  "Savings" => {
    templates: [
      "Emergency fund transfer",
      "Retirement contribution",
      "Investment deposit",
      "Savings account transfer"
    ],
    amount_range: [100.00, 2000.00],
    frequency: 0.02
  }
}

# Generate transactions for each user
all_transactions = []

created_users.each do |user|
  puts "Generating #{TOTAL_TRANSACTIONS} transactions for user: #{user.email}"
  user_categories = user.categories.index_by(&:name)
  
  transactions_created = 0
  batch_transactions = []
  
  # Generate transactions in batches
  (TOTAL_TRANSACTIONS / BATCH_SIZE).times do |batch_num|
    batch_start_time = Time.current
    
    BATCH_SIZE.times do
      # Determine category based on frequency
      category_name = transaction_patterns.keys.sample
      pattern_data = transaction_patterns[category_name]
      
      # Skip if category doesn't exist for this user
      next unless user_categories[category_name]
      
      # Occasionally leave transactions uncategorized (0.3% chance)
      category_name = nil if rand < 0.003
      
      # Generate transaction details
      if category_name
        template = pattern_data[:templates].sample
        description = generate_description(template, pattern_data)
        amount = generate_amount(pattern_data[:amount_range], category_name)
      else
        # Generate generic description for uncategorized transactions
        generic_descriptions = [
          "Transaction #{rand(100000..999999)}",
          "Payment to #{['Vendor', 'Merchant', 'Business', 'Service'].sample} #{rand(1000..9999)}",
          "Charge from #{['Store', 'Restaurant', 'Business'].sample}",
          "Purchase at #{['Location', 'Store', 'Business'].sample} #{rand(100..999)}",
          "Transfer to #{['Account', 'Person', 'Business'].sample}",
          "Fee from #{['Bank', 'Service', 'Provider'].sample}",
          "Refund from #{['Store', 'Business', 'Service'].sample}",
          "Adjustment #{rand(1000..9999)}"
        ]
        description = generic_descriptions.sample
        amount = -rand(1.00..1000.00).round(2)
      end
      date = generate_random_date(START_DATE, END_DATE)
      
      # Add rare edge cases for anomaly testing
      if rand < 0.0002  # 0.02% chance for questionable amounts
        amount = generate_questionable_amount(amount, category_name)
      end
      description = nil if rand < 0.0001  # 0.01% chance for missing description
      
      # Create transaction
      transaction_data = {
        user_id: user.id,
        category_id: category_name ? user_categories[category_name]&.id : nil,
        description: description,
        amount: amount,
        date: date,
        created_at: Time.current,
        updated_at: Time.current
      }
      
      batch_transactions << transaction_data
      transactions_created += 1
      
      # Add some uncategorized transactions (0.1% chance)
      if rand < 0.001
        # Generate various types of suspicious uncategorized transactions
        suspicious_types = [
          { template: "Mystery charge - #{rand(1000..9999)}", amount_range: [5.00, 250.00] },
          { template: "Unknown transaction", amount_range: [0.01, 1000.00] },
          { template: "Pending charge", amount_range: [1.00, 500.00] },
          { template: "ATM withdrawal - #{rand(1000..9999)}", amount_range: [20.00, 500.00] },
          { template: "Cash advance", amount_range: [100.00, 2000.00] },
          { template: "Wire transfer", amount_range: [500.00, 10000.00] },
          { template: "Foreign transaction fee", amount_range: [1.00, 50.00] },
          { template: "Overdraft fee", amount_range: [25.00, 50.00] },
          { template: "Late payment fee", amount_range: [15.00, 75.00] }
        ]
        
        suspicious_type = suspicious_types.sample
        uncategorized_template = suspicious_type[:template]
        uncategorized_amount = -rand(suspicious_type[:amount_range][0]..suspicious_type[:amount_range][1]).round(2)
        
        # Make some uncategorized transactions more suspicious
        is_uncategorized_questionable = false
        if rand < 0.5  # 50% of uncategorized are suspicious (but this is now a much smaller pool)
          uncategorized_amount = generate_questionable_amount(uncategorized_amount, "Miscellaneous")
          is_uncategorized_questionable = true
        end
        
        uncategorized_transaction_data = {
          user_id: user.id,
          category_id: nil,
          description: uncategorized_template,
          amount: uncategorized_amount,
          date: generate_random_date(START_DATE, END_DATE),
          created_at: Time.current,
          updated_at: Time.current
        }
        
        batch_transactions << uncategorized_transaction_data
        transactions_created += 1
      end
    end
    
    # Bulk insert transactions
    if batch_transactions.any?
      Transaction.insert_all(batch_transactions)
      batch_transactions.clear
    end
    
    batch_time = Time.current - batch_start_time
    puts "  Batch #{batch_num + 1}: #{transactions_created} transactions created (#{batch_time.round(2)}s)"
  end
  
  puts "  Total: #{transactions_created} transactions created for #{user.email}"
end

puts "Created #{Transaction.count} total transactions"

# Create categorization rules
puts "Creating categorization rules..."

rule_templates = [
  { name: "Starbucks Coffee", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Starbucks" }, priority: 1 },
  { name: "McDonald's Fast Food", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "McDonald's" }, priority: 2 },
  { name: "Amazon Purchases", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Amazon" }, priority: 3 },
  { name: "High Value Purchases", rule_predicate: { "type" => "NUMBER", "column" => "amount", "operator" => "LESS_THAN", "operand" => -100 }, priority: 4 },
  { name: "Income Transactions", rule_predicate: { "type" => "NUMBER", "column" => "amount", "operator" => "GREATER_THAN", "operand" => 0 }, priority: 5 },
  { name: "Uber Rides", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Uber" }, priority: 6 },
  { name: "Netflix Subscription", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Netflix" }, priority: 7 },
  { name: "Salary Deposits", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Salary" }, priority: 8 },
]

created_users.each do |user|
  food_category = user.categories.find_by(name: "Food & Dining")
  shopping_category = user.categories.find_by(name: "Shopping")
  income_category = user.categories.find_by(name: "Income")
  transportation_category = user.categories.find_by(name: "Transportation")
  entertainment_category = user.categories.find_by(name: "Entertainment")
  
  rules = [
    { name: "Starbucks Coffee", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Starbucks" }, priority: 1, category: food_category },
    { name: "McDonald's Fast Food", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "McDonald's" }, priority: 2, category: food_category },
    { name: "Amazon Purchases", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Amazon" }, priority: 3, category: shopping_category },
    { name: "High Value Purchases", rule_predicate: { "type" => "NUMBER", "column" => "amount", "operator" => "LESS_THAN", "operand" => -100 }, priority: 4, category: shopping_category },
    { name: "Income Transactions", rule_predicate: { "type" => "NUMBER", "column" => "amount", "operator" => "GREATER_THAN", "operand" => 0 }, priority: 5, category: income_category },
    { name: "Uber Rides", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Uber" }, priority: 6, category: transportation_category },
    { name: "Netflix Subscription", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Netflix" }, priority: 7, category: entertainment_category },
    { name: "Salary Deposits", rule_predicate: { "type" => "STRING", "column" => "description", "operator" => "CONTAINS", "operand" => "Salary" }, priority: 8, category: income_category },
  ]
  
  rules.each do |rule_data|
    CategorizationRule.create!(
      user: user,
      category: rule_data[:category],
      name: rule_data[:name],
      rule_predicate: rule_data[:rule_predicate],
      priority: rule_data[:priority],
      active: true
    )
  end
end

puts "Created categorization rules"


# Apply categorization rules to uncategorized transactions
puts "Applying categorization rules..."

created_users.each do |user|
  puts "Applying categorization rules for #{user.email}..."
  
  # Get all active rules for this user
  rules = user.categorization_rules.active.by_priority
  
  # Find uncategorized transactions in batches
  uncategorized_transactions = user.transactions.where(category: nil)
  total_uncategorized = uncategorized_transactions.count
  updated_count = 0
  
  puts "  Found #{total_uncategorized} uncategorized transactions"
  
  # Process in batches of 1000 for memory efficiency
  uncategorized_transactions.find_in_batches(batch_size: 1000) do |batch|
    batch_updates = []
    
    batch.each do |transaction|
      rules.each do |rule|
        if rule.matches_transaction?(transaction)
          batch_updates << {
            id: transaction.id,
            user_id: transaction.user_id,
            category_id: rule.category.id,
            updated_at: Time.current
          }
          break
        end
      end
    end
    
    # Batch update transactions
    if batch_updates.any?
      Transaction.upsert_all(batch_updates, update_only: [:category_id])
      updated_count += batch_updates.length
      puts "  Updated #{updated_count}/#{total_uncategorized} transactions..." if updated_count % 5000 == 0
    end
  end
  
  puts "  Completed: #{updated_count} transactions categorized for #{user.email}"
end

puts "Applied categorization rules to uncategorized transactions"

puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "Users: #{User.count}"
puts "Categories: #{Category.count}"
puts "Transactions: #{Transaction.count}"
puts "Categorization Rules: #{CategorizationRule.count}"
puts "="*50

puts "\nTest accounts created:"
created_users.each do |user|
  puts "- Email: #{user.email} | Password: demo1234"
end

# Run bulk anomaly detection on all transactions
puts "\nRunning bulk anomaly detection..."
created_users.each do |user|
  puts "Detecting anomalies for user: #{user.email}..."
  BulkAnomalyDetectionJob.perform_now(user.id)
  puts "  Anomaly detection completed for #{user.email}"
end

puts "\nFinal anomaly count: #{Anomaly.count}"

puts "\nSeed data creation completed successfully! 🌱"