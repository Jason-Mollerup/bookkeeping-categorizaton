#!/usr/bin/env ruby

# Standalone transaction data generator
# Usage: ruby scripts/generate_transactions.rb [count] [output_file]

require 'csv'
require 'date'
require 'json'
require 'fileutils'

class TransactionGenerator
  def initialize
    @patterns = {
      # Food & Dining patterns (matches seed data)
      food: {
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
        amounts: (3.50..85.00),
        category_weight: 0.25,
        category_name: "Food & Dining"
      },
      
      # Transportation patterns (matches seed data)
      transport: {
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
        amounts: (2.50..85.00),
        category_weight: 0.15,
        category_name: "Transportation"
      },
      
      # Shopping patterns (matches seed data)
      shopping: {
        templates: [
          "Amazon purchase - {item}",
          "Target - {item}",
          "Walmart - {item}",
          "Best Buy - {item}",
          "Online order from {store}"
        ],
        items: ["electronics", "clothing", "home goods", "books", "toys"],
        stores: ["Amazon", "Target", "Walmart", "Best Buy", "Home Depot"],
        amounts: (12.99..899.99),
        category_weight: 0.20,
        category_name: "Shopping"
      },
      
      # Entertainment patterns (matches seed data)
      entertainment: {
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
        amounts: (9.99..299.99),
        category_weight: 0.08,
        category_name: "Entertainment"
      },
      
      # Bills & Utilities patterns (matches seed data)
      bills: {
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
        amounts: (45.00..2500.00),
        category_weight: 0.12,
        category_name: "Bills & Utilities"
      },
      
      # Healthcare patterns (matches seed data)
      healthcare: {
        templates: [
          "Doctor visit - {specialty}",
          "Pharmacy - {medication}",
          "Dental cleaning",
          "Eye exam",
          "Prescription - {medication}"
        ],
        specialties: ["general", "dermatology", "cardiology", "orthopedics"],
        medications: ["antibiotics", "pain relief", "vitamins", "prescription"],
        amounts: (25.00..850.00),
        category_weight: 0.06,
        category_name: "Healthcare"
      },
      
      # Travel patterns (matches seed data)
      travel: {
        templates: [
          "Hotel booking - {location}",
          "Flight tickets - {airline}",
          "Rental car - {company}",
          "Airbnb - {location}"
        ],
        locations: ["New York", "Los Angeles", "Chicago", "Miami", "Seattle"],
        airlines: ["American", "Delta", "United", "Southwest"],
        companies: ["Hertz", "Enterprise", "Avis", "Budget"],
        amounts: (150.00..3500.00),
        category_weight: 0.04,
        category_name: "Travel"
      },
      
      # Income patterns (matches seed data)
      income: {
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
        amounts: (25.00..8500.00),
        category_weight: 0.08,
        category_name: "Income"
      },
      
      # Savings patterns (matches seed data)
      savings: {
        templates: [
          "Emergency fund transfer",
          "Retirement contribution",
          "Investment deposit",
          "Savings account transfer"
        ],
        amounts: (100.00..2000.00),
        category_weight: 0.02,
        category_name: "Savings"
      }
    }
    
    @categories = create_categories
  end
  
  def generate(count, output_file = nil)
    output_file ||= "scripts/dummy_data/transactions_#{count}_#{Date.today.strftime('%Y%m%d')}.csv"
    
    puts "🚀 Generating #{count} transactions..."
    puts "📁 Output file: #{output_file}"
    puts "📊 Using #{@categories.count} categories"
    
    transactions = []
    start_date = Date.today - (2 * 365) # 2 years ago
    end_date = Date.today
    
    # Create weighted category mapping
    category_weights = create_category_weights
    
    count.times do |i|
      # Select category based on weights
      selected_category = weighted_random_choice(category_weights)
      
      # Find matching pattern
      pattern_name = find_pattern_for_category(selected_category)
      pattern = @patterns[pattern_name] || @patterns[:food] # fallback
      
      # Generate transaction data using templates
      if pattern[:templates]
        template = pattern[:templates].sample
        description = generate_description_from_template(template, pattern)
      else
        # Fallback for old format
        description = pattern[:descriptions]&.sample || "Transaction #{i}"
      end
      
      amount = generate_realistic_amount(pattern[:amounts], pattern_name)
      date = generate_realistic_date(start_date, end_date, pattern_name)
      
      # Add rare edge cases (matching seed data)
      if rand < 0.001  # 0.1% chance for questionable amounts
        amount = generate_questionable_amount(amount, pattern_name)
      end
      
      if rand < 0.0005  # 0.05% chance for missing descriptions
        description = nil
      end
      
      if rand < 0.02  # 2% chance for missing categories
        selected_category = { id: nil, name: nil }
      end
      
      # Add some randomness to description (30% chance)
      if description && rand < 0.3
        description = add_description_variation(description, amount)
      end
      
      
      # Create transaction hash (for CSV export)
      transaction = {
        amount: amount,
        description: description,
        date: date,
        category_id: selected_category[:id],
        category_name: selected_category[:name]
      }
      
      transactions << transaction
      
      # Progress indicator
      if (i + 1) % 10000 == 0
        puts "  Generated #{i + 1} transactions..."
      end
    end
    
    # Export to CSV
    export_to_csv(transactions, output_file)
    
    puts "✅ Generated #{transactions.count} transactions"
    puts "📄 Saved to: #{output_file}"
    puts "💾 File size: #{File.size(output_file) / 1024} KB"
    
    # Show summary statistics
    show_summary(transactions)
  end
  
  private
  
  def create_categories
    [
      { id: 1, name: "Food & Dining", color: "#FF6B6B" },
      { id: 2, name: "Transportation", color: "#4ECDC4" },
      { id: 3, name: "Shopping", color: "#45B7D1" },
      { id: 4, name: "Entertainment", color: "#96CEB4" },
      { id: 5, name: "Bills & Utilities", color: "#FFEAA7" },
      { id: 6, name: "Healthcare", color: "#DDA0DD" },
      { id: 7, name: "Travel", color: "#98D8C8" },
      { id: 8, name: "Income", color: "#82E0AA" },
      { id: 9, name: "Savings", color: "#85C1E9" },
      { id: 10, name: "Miscellaneous", color: "#F8C471" }
    ]
  end
  
  def create_category_weights
    weights = {}
    @patterns.each do |pattern_name, pattern_data|
      category = @categories.find { |c| c[:name] == pattern_data[:category_name] }
      if category
        weights[category] = pattern_data[:category_weight]
      end
    end
    
    # Add remaining categories with small weights
    remaining_categories = @categories - weights.keys
    remaining_categories.each do |category|
      weights[category] = 0.01
    end
    
    weights
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
  
  def find_pattern_for_category(category)
    category_name = category[:name].downcase
    
    @patterns.each do |pattern_name, pattern_data|
      if category_name.include?(pattern_name.to_s) || 
         category_name.include?(pattern_data[:category_name].downcase.split.first)
        return pattern_name
      end
    end
    
    # Try partial matches
    if category_name.include?("food") || category_name.include?("dining")
      return :food
    elsif category_name.include?("transport")
      return :transport
    elsif category_name.include?("shop")
      return :shopping
    elsif category_name.include?("bill") || category_name.include?("utility")
      return :bills
    elsif category_name.include?("entertainment")
      return :entertainment
    elsif category_name.include?("health") || category_name.include?("medical")
      return :healthcare
    elsif category_name.include?("travel")
      return :travel
    elsif category_name.include?("business")
      return :business
    end
    
    :food # default fallback
  end
  
  def generate_description_from_template(template, pattern)
    description = template.dup
    
    # Replace placeholders with random values
    description.gsub!(/\{store\}/, pattern[:stores]&.sample || "Store")
    description.gsub!(/\{restaurant\}/, pattern[:restaurants]&.sample || "Restaurant")
    description.gsub!(/\{coffee_shop\}/, pattern[:coffee_shops]&.sample || "Coffee Shop")
    description.gsub!(/\{delivery_service\}/, pattern[:delivery_services]&.sample || "Delivery")
    description.gsub!(/\{cafe\}/, pattern[:cafes]&.sample || "Cafe")
    description.gsub!(/\{convenience_store\}/, pattern[:convenience_stores]&.sample || "Store")
    description.gsub!(/\{item\}/, pattern[:items]&.sample || "item")
    description.gsub!(/\{station\}/, pattern[:stations]&.sample || "Station")
    description.gsub!(/\{destination\}/, pattern[:destinations]&.sample || "destination")
    description.gsub!(/\{location\}/, pattern[:locations]&.sample || "location")
    description.gsub!(/\{theater\}/, pattern[:theaters]&.sample || "Theater")
    description.gsub!(/\{game\}/, pattern[:games]&.sample || "Game")
    description.gsub!(/\{service\}/, pattern[:services]&.sample || "Service")
    description.gsub!(/\{month\}/, pattern[:months]&.sample || "Month")
    description.gsub!(/\{provider\}/, pattern[:providers]&.sample || "Provider")
    description.gsub!(/\{carrier\}/, pattern[:carriers]&.sample || "Carrier")
    description.gsub!(/\{type\}/, pattern[:types]&.sample || "Type")
    description.gsub!(/\{specialty\}/, pattern[:specialties]&.sample || "Specialty")
    description.gsub!(/\{medication\}/, pattern[:medications]&.sample || "Medication")
    description.gsub!(/\{airline\}/, pattern[:airlines]&.sample || "Airline")
    description.gsub!(/\{company\}/, pattern[:companies]&.sample || "Company")
    description.gsub!(/\{client\}/, pattern[:clients]&.sample || "Client")
    description.gsub!(/\{source\}/, pattern[:sources]&.sample || "Source")
    
    description
  end

  def generate_realistic_amount(amount_range, pattern_name)
    base_amount = rand(amount_range)
    
    # Add realistic pricing patterns (matching seed data)
    case pattern_name
    when :food
      # Often ends in .99, .95, .49
      endings = [0.99, 0.95, 0.49, 0.00, 0.50]
      base_amount = base_amount.floor + endings.sample
    when :transport
      # Gas often has 3 decimal places
      if rand < 0.3
        base_amount = (base_amount * 1000).round / 1000.0
      end
    when :bills
      # Often round numbers
      base_amount = base_amount.round
    when :shopping
      # Often ends in .99
      if rand < 0.6
        base_amount = base_amount.floor + 0.99
      end
    end
    
    # Income is positive, expenses are negative
    if pattern_name == :income
      base_amount.abs
    else
      -base_amount.abs
    end
  end

  def generate_questionable_amount(original_amount, pattern_name)
    # Generate questionable amounts that would trigger anomaly detection
    questionable_patterns = [
      # Extremely high amounts
      original_amount * rand(50..200),
      
      # Suspiciously round amounts for non-bill categories
      case pattern_name
      when :food, :transport, :shopping, :entertainment
        # Round amounts are suspicious for these categories
        rand(100..5000).to_i * 100  # $100, $200, $300, etc.
      else
        original_amount * rand(50..200)
      end,
      
      # Negative amounts for income categories (should be positive)
      if pattern_name == :income
        -rand(1000..10000).abs
      else
        original_amount * rand(50..200)
      end,
      
      # Positive amounts for expense categories (should be negative)
      if pattern_name != :income
        rand(100..5000).abs
      else
        original_amount * rand(50..200)
      end,
      
      # Suspiciously low amounts for high-value categories
      case pattern_name
      when :travel, :healthcare, :bills
        rand(0.01..5.00)  # Very low for these categories
      else
        original_amount * rand(50..200)
      end,
      
      # Suspiciously high amounts for low-value categories
      case pattern_name
      when :food, :transport
        rand(1000..50000)  # Very high for these categories
      else
        original_amount * rand(50..200)
      end
    ]
    
    questionable_patterns.sample
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
      "#{description} - #{['Tax', 'Tip', 'Fee'].sample}",
      "#{description} - #{['Store', 'Location'].sample} #{rand(1..99)}",
      "#{description} - #{['Transaction', 'Purchase', 'Payment'].sample} #{rand(1..999)}"
    ]
    
    # 30% chance of variation
    rand < 0.3 ? variations.sample : description
  end
  
  
  def export_to_csv(transactions, filename)
    CSV.open(filename, 'w', write_headers: true, headers: [
      'amount', 'description', 'date', 'category_id', 'category_name'
    ]) do |csv|
      transactions.each do |transaction|
        csv << [
          transaction[:amount],
          transaction[:description],
          transaction[:date].strftime('%Y-%m-%d'),
          transaction[:category_id],
          transaction[:category_name]
        ]
      end
    end
  end
  
  def show_summary(transactions)
    puts "\n📊 Summary Statistics:"
    puts "  Total transactions: #{transactions.count}"
    puts "  Date range: #{transactions.map { |t| t[:date] }.minmax.join(' to ')}"
    puts "  Amount range: $#{transactions.map { |t| t[:amount] }.minmax.join(' to $')}"
    
    # Category breakdown
    category_counts = transactions.group_by { |t| t[:category_name] }
                                 .transform_values(&:count)
                                 .sort_by { |_, count| -count }
    
    puts "\n📈 Category Breakdown:"
    category_counts.each do |category, count|
      percentage = (count.to_f / transactions.count * 100).round(1)
      puts "  #{category}: #{count} (#{percentage}%)"
    end
  end
end

# Main execution
if __FILE__ == $0
  count = ARGV[0]&.to_i || 1000
  output_file = ARGV[1]
  
  if count <= 0
    puts "❌ Count must be a positive number"
    exit 1
  end
  
  # Ensure output directory exists
  FileUtils.mkdir_p('scripts/dummy_data') unless Dir.exist?('scripts/dummy_data')
  
  generator = TransactionGenerator.new
  generator.generate(count, output_file)
end
