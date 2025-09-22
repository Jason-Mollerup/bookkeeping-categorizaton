require 'csv'

namespace :data do
  desc "Generate dummy transaction data and export to CSV"
  task :generate, [:count, :user_email, :output_file] => :environment do |t, args|
    count = (args[:count] || 1000).to_i
    user_email = args[:user_email] || "test@example.com"
    output_file = args[:output_file] || "scripts/dummy_data/transactions_#{count}_#{Date.current.strftime('%Y%m%d')}.csv"
    
    puts "🚀 Generating #{count} transactions for user: #{user_email}"
    puts "📁 Output file: #{output_file}"
    
    # Ensure output directory exists
    FileUtils.mkdir_p('scripts/dummy_data') unless Dir.exist?('scripts/dummy_data')
    
    # Find or create user
    user = User.find_by(email: user_email)
    unless user
      puts "❌ User not found: #{user_email}"
      puts "Available users: #{User.pluck(:email).join(', ')}"
      exit 1
    end
    
    # Get user's categories
    categories = user.categories.to_a
    if categories.empty?
      puts "⚠️  No categories found for user. Creating default categories..."
      categories = create_default_categories(user)
    end
    
    puts "📊 Using #{categories.count} categories"
    
    # Generate transactions
    transactions = generate_transactions(user, categories, count)
    
    # Export to CSV
    export_to_csv(transactions, output_file)
    
    puts "✅ Generated #{transactions.count} transactions"
    puts "📄 Saved to: #{output_file}"
    puts "💾 File size: #{File.size(output_file) / 1024} KB"
  end
  
  desc "Generate sample data for different scenarios"
  task :scenarios => :environment do
    scenarios = {
      small: { count: 100, name: "Small dataset" },
      medium: { count: 10000, name: "Medium dataset" },
      large: { count: 100000, name: "Large dataset" },
      massive: { count: 1000000, name: "Massive dataset (1M+)" }
    }
    
    user_email = "test@example.com"
    
    scenarios.each do |key, config|
      puts "\n🎯 Generating #{config[:name]} (#{config[:count]} transactions)..."
      
      output_file = "transactions_#{key}_#{config[:count]}_#{Date.current.strftime('%Y%m%d')}.csv"
      
      Rake::Task["data:generate"].invoke(config[:count], user_email, output_file)
      Rake::Task["data:generate"].reenable
    end
  end
  
  private
  
  def create_default_categories(user)
    categories_data = [
      { name: "Food & Dining", color: "#FF6B6B" },
      { name: "Transportation", color: "#4ECDC4" },
      { name: "Shopping", color: "#45B7D1" },
      { name: "Entertainment", color: "#96CEB4" },
      { name: "Bills & Utilities", color: "#FFEAA7" },
      { name: "Healthcare", color: "#DDA0DD" },
      { name: "Travel", color: "#98D8C8" },
      { name: "Education", color: "#F7DC6F" },
      { name: "Business", color: "#BB8FCE" },
      { name: "Other", color: "#85C1E9" }
    ]
    
    categories_data.map do |cat_data|
      user.categories.create!(cat_data)
    end
  end
  
  def generate_transactions(user, categories, count)
    transactions = []
    start_date = 2.years.ago.to_date
    end_date = Date.current
    
    # Transaction patterns for realistic data
    patterns = {
      # Food & Dining patterns
      food: {
        descriptions: [
          "Starbucks Coffee", "McDonald's", "Subway", "Pizza Hut", "Domino's",
          "Chipotle", "Taco Bell", "KFC", "Burger King", "Wendy's",
          "Whole Foods", "Safeway", "Kroger", "Walmart Grocery", "Target",
          "Restaurant ABC", "Cafe XYZ", "Deli Corner", "Food Truck", "Grocery Store"
        ],
        amounts: (5.00..150.00),
        category_weight: 0.25
      },
      
      # Transportation patterns
      transport: {
        descriptions: [
          "Uber Ride", "Lyft", "Taxi", "Gas Station", "Shell", "Exxon",
          "BP", "Chevron", "Public Transit", "Metro Card", "Bus Pass",
          "Parking Fee", "Toll Road", "Car Wash", "Auto Repair", "Oil Change",
          "DMV Fee", "Registration", "Insurance", "Car Payment"
        ],
        amounts: (10.00..500.00),
        category_weight: 0.15
      },
      
      # Shopping patterns
      shopping: {
        descriptions: [
          "Amazon Purchase", "Target", "Walmart", "Best Buy", "Home Depot",
          "Lowe's", "Costco", "Sam's Club", "Macy's", "Nordstrom",
          "Online Store", "Retail Shop", "Department Store", "Electronics",
          "Clothing Store", "Shoe Store", "Bookstore", "Gift Shop"
        ],
        amounts: (20.00..2000.00),
        category_weight: 0.20
      },
      
      # Bills & Utilities patterns
      bills: {
        descriptions: [
          "Electric Bill", "Water Bill", "Gas Bill", "Internet", "Phone Bill",
          "Cable TV", "Rent", "Mortgage", "Insurance", "Credit Card Payment",
          "Loan Payment", "Property Tax", "HOA Fee", "Trash Service"
        ],
        amounts: (50.00..2000.00),
        category_weight: 0.15
      },
      
      # Entertainment patterns
      entertainment: {
        descriptions: [
          "Netflix", "Spotify", "Apple Music", "Movie Theater", "Concert",
          "Sports Game", "Museum", "Theater", "Gaming", "Streaming Service",
          "Hulu", "Disney+", "Amazon Prime", "YouTube Premium", "Gym Membership"
        ],
        amounts: (5.00..500.00),
        category_weight: 0.10
      },
      
      # Healthcare patterns
      healthcare: {
        descriptions: [
          "Doctor Visit", "Pharmacy", "CVS", "Walgreens", "Medical Test",
          "Dental Visit", "Eye Exam", "Prescription", "Hospital", "Clinic",
          "Health Insurance", "Medical Equipment", "Therapy", "Lab Work"
        ],
        amounts: (25.00..2000.00),
        category_weight: 0.08
      },
      
      # Travel patterns
      travel: {
        descriptions: [
          "Airline Ticket", "Hotel", "Airbnb", "Rental Car", "Train Ticket",
          "Bus Ticket", "Cruise", "Vacation Rental", "Travel Insurance",
          "Airport Parking", "Baggage Fee", "Travel Agency", "Tour Guide"
        ],
        amounts: (100.00..5000.00),
        category_weight: 0.05
      },
      
      # Business patterns
      business: {
        descriptions: [
          "Office Supplies", "Software License", "Conference", "Business Lunch",
          "Client Meeting", "Professional Services", "Consulting", "Training",
          "Equipment Purchase", "Business Travel", "Marketing", "Advertising"
        ],
        amounts: (50.00..5000.00),
        category_weight: 0.02
      }
    }
    
    # Create weighted category mapping
    category_weights = {}
    patterns.each do |pattern_name, pattern_data|
      category = categories.find { |c| c.name.downcase.include?(pattern_name.to_s) }
      if category
        category_weights[category] = pattern_data[:category_weight]
      end
    end
    
    # Add remaining categories with small weights
    remaining_categories = categories - category_weights.keys
    remaining_categories.each do |category|
      category_weights[category] = 0.01
    end
    
    # Generate transactions
    count.times do |i|
      # Select category based on weights
      selected_category = weighted_random_choice(category_weights)
      
      # Find matching pattern
      pattern_name = find_pattern_for_category(selected_category, patterns)
      pattern = patterns[pattern_name] || patterns[:food] # fallback
      
      # Generate transaction data
      description = pattern[:descriptions].sample
      amount = generate_realistic_amount(pattern[:amounts], pattern_name)
      date = generate_realistic_date(start_date, end_date, pattern_name)
      
      # Add some randomness to description
      description = add_description_variation(description, amount)
      
      # Generate metadata
      metadata = generate_metadata(pattern_name, amount)
      
      # Create transaction hash (for CSV export)
      transaction = {
        amount: amount,
        description: description,
        date: date,
        category_id: selected_category.id,
        category_name: selected_category.name,
        flagged: rand < 0.05, # 5% chance of being flagged
        reviewed: rand < 0.8,  # 80% chance of being reviewed
        metadata: metadata.to_json
      }
      
      transactions << transaction
      
      # Progress indicator
      if (i + 1) % 10000 == 0
        puts "  Generated #{i + 1} transactions..."
      end
    end
    
    transactions
  end
  
  def weighted_random_choice(weights)
    total_weight = weights.values.sum
    random_value = rand * total_weight
    
    current_weight = 0
    weights.each do |category, weight|
      current_weight += weight
      return category if random_value <= current_weight
    end
    
    weights.keys.last # fallback
  end
  
  def find_pattern_for_category(category, patterns)
    category_name = category.name.downcase
    
    patterns.each do |pattern_name, _|
      if category_name.include?(pattern_name.to_s)
        return pattern_name
      end
    end
    
    # Try partial matches
    if category_name.include?("food") || category_name.include?("dining")
      return :food
    elsif category_name.include?("transport") || category_name.include?("gas")
      return :transport
    elsif category_name.include?("shop") || category_name.include?("retail")
      return :shopping
    elsif category_name.include?("bill") || category_name.include?("utility")
      return :bills
    elsif category_name.include?("entertainment") || category_name.include?("fun")
      return :entertainment
    elsif category_name.include?("health") || category_name.include?("medical")
      return :healthcare
    elsif category_name.include?("travel") || category_name.include?("vacation")
      return :travel
    elsif category_name.include?("business") || category_name.include?("work")
      return :business
    end
    
    :food # default fallback
  end
  
  def generate_realistic_amount(amount_range, pattern_name)
    base_amount = rand(amount_range)
    
    # Add some realistic variations
    case pattern_name
    when :food
      # Food amounts often end in .99, .95, .49, etc.
      cents = [99, 95, 49, 50, 00].sample
      base_amount = (base_amount.floor + cents / 100.0).round(2)
    when :bills
      # Bills are often round numbers
      base_amount = base_amount.round
    when :transport
      # Gas prices often have 3 decimal places
      base_amount = (base_amount * 1000).round / 1000.0
    end
    
    # Ensure amount is not zero
    base_amount = 0.01 if base_amount <= 0
    
    base_amount.round(2)
  end
  
  def generate_realistic_date(start_date, end_date, pattern_name)
    # Some patterns have seasonal variations
    case pattern_name
    when :travel
      # Travel is more common in summer and holidays
      if rand < 0.6
        # Summer months (June-August) or December
        summer_months = [6, 7, 8, 12]
        month = summer_months.sample
        year = rand(start_date.year..end_date.year)
        day = rand(1..28)
        return Date.new(year, month, day)
      end
    when :bills
      # Bills often occur at month end
      if rand < 0.3
        return end_date - rand(0..5)
      end
    end
    
    # Random date within range
    rand(start_date..end_date)
  end
  
  def add_description_variation(description, amount)
    variations = [
      "#{description} - #{amount}",
      "#{description} #{rand(1..999)}",
      "#{description} - #{['Inc', 'LLC', 'Corp'].sample}",
      "#{description} - #{['Store', 'Location', 'Branch'].sample} #{rand(1..99)}",
      "#{description} - #{['Online', 'Mobile', 'App'].sample}",
      "#{description} - #{['Refund', 'Credit', 'Adjustment'].sample}",
      "#{description} - #{['Tax', 'Tip', 'Fee'].sample}"
    ]
    
    # 30% chance of variation
    rand < 0.3 ? variations.sample : description
  end
  
  def generate_metadata(pattern_name, amount)
    metadata = {
      generated_at: Time.current.iso8601,
      pattern: pattern_name.to_s,
      amount_tier: case amount
                   when 0..50 then "low"
                   when 50..200 then "medium"
                   when 200..1000 then "high"
                   else "very_high"
                   end
    }
    
    # Add pattern-specific metadata
    case pattern_name
    when :food
      metadata[:meal_type] = ["breakfast", "lunch", "dinner", "snack"].sample
      metadata[:location] = ["dine_in", "takeout", "delivery"].sample
    when :transport
      metadata[:vehicle_type] = ["car", "uber", "lyft", "public_transit"].sample
      metadata[:distance] = "#{rand(1..50)} miles"
    when :shopping
      metadata[:store_type] = ["online", "physical", "marketplace"].sample
      metadata[:item_count] = rand(1..10)
    when :bills
      metadata[:bill_type] = ["recurring", "one_time", "overdue"].sample
      metadata[:due_date] = (Date.current + rand(1..30)).iso8601
    when :entertainment
      metadata[:entertainment_type] = ["streaming", "live_event", "subscription"].sample
      metadata[:duration] = "#{rand(1..4)} hours"
    when :healthcare
      metadata[:provider_type] = ["doctor", "pharmacy", "hospital", "clinic"].sample
      metadata[:insurance_covered] = rand < 0.7
    when :travel
      metadata[:trip_type] = ["business", "leisure", "family"].sample
      metadata[:destination] = ["domestic", "international"].sample
    when :business
      metadata[:expense_type] = ["operational", "marketing", "travel", "equipment"].sample
      metadata[:reimbursable] = rand < 0.8
    end
    
    metadata
  end
  
  def export_to_csv(transactions, filename)
    CSV.open(filename, 'w', write_headers: true, headers: [
      'amount', 'description', 'date', 'category_id', 'category_name', 
      'flagged', 'reviewed', 'metadata'
    ]) do |csv|
      transactions.each do |transaction|
        csv << [
          transaction[:amount],
          transaction[:description],
          transaction[:date].strftime('%Y-%m-%d'),
          transaction[:category_id],
          transaction[:category_name],
          transaction[:flagged],
          transaction[:reviewed],
          transaction[:metadata]
        ]
      end
    end
  end
end
