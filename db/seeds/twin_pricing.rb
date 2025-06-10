# db/seeds/twin_pricing.rb
# Seed file for Twin Kiddies and Twin Newborn pricing

puts "🌱 Seeding Twin Pricing Data..."

twin_pricing_data = [
  {
    name: "Twin Kiddies Session",
    description: "Special photography session designed for twin children. Includes individual shots of each child and adorable twin poses together. Studio props to keep them engaged.",
    amount: 60000, # $550.00 (premium for handling two kids)
    discount: 0.0,
    duration: 90, # Longer session for two children
    included: "5", # More photos since there are two subjects
    shoot_type: "Twin Kiddies",
    icon: "fa-users", # Represents the twin concept
    outfit: "1 Outfit",
    period: ""
  },
  {
    name: "Twin Kiddies Session",
    description: "Premium twin children photography package with extended session time, multiple backdrop changes, and comprehensive editing. Perfect for capturing the unique bond between twins.",
    amount: 90000, # $700.00
    discount: 0.0,
    duration: 120, # Extended time for outfit changes and variety
    included: "8",
    shoot_type: "Twin Kiddies",
    icon: "fa-users",
    outfit: "2 Outfits",
    period: ""
  },
    {
    name: "Twin Kiddies Session",
    description: "Premium twin children photography package with extended session time, multiple backdrop changes, and comprehensive editing. Perfect for capturing the unique bond between twins.",
    amount: 120000, # $700.00
    discount: 0.0,
    duration: 120, # Extended time for outfit changes and variety
    included: "12",
    shoot_type: "Twin Kiddies",
    icon: "fa-users",
    outfit: "3 Outfits",
    period: ""
  },
    {
    name: "Twin Kiddies Session",
    description: "Premium twin children photography package with extended session time, multiple backdrop changes, and comprehensive editing. Perfect for capturing the unique bond between twins.",
    amount: 155000, # $700.00
    discount: 0.0,
    duration: 120, # Extended time for outfit changes and variety
    included: "15",
    shoot_type: "Twin Kiddies",
    icon: "fa-users",
    outfit: "4 Outfits",
    period: ""
  },
    {
    name: "Twin Kiddies Session",
    description: "Premium twin children photography package with extended session time, multiple backdrop changes, and comprehensive editing. Perfect for capturing the unique bond between twins.",
    amount: 185000, # $700.00
    discount: 0.0,
    duration: 120, # Extended time for outfit changes and variety
    included: "18",
    shoot_type: "Twin Kiddies",
    icon: "fa-users",
    outfit: "5 Outfits",
    period: ""
  },
  {
    name: "Twin Newborn",
    description: "Gentle and safe newborn photography session for twin babies. Includes individual portraits and beautiful twin poses. Specialized in handling newborn twins with extra care and patience.",
    amount: 90000, # $800.00 (premium for newborn expertise + twins)
    discount: 0.0,
    duration: 150, # Longer for feeding/changing breaks
    included: "7",
    shoot_type: "Twin Newborn",
    icon: "fa-baby",
    outfit: "1 Outfit",
    period: ""
  },
  {
    name: "Twin Newborn",
    description: "Luxury newborn photography experience for twin babies. Includes artistic poses, beautiful props, and heirloom-quality editing. Multiple setup changes and family shots included.",
    amount: 150000, # $1200.00
    discount: 0.0,
    duration: 180, # 3 hours for comprehensive session
    included: "10",
    shoot_type: "Twin Newborn",
    icon: "fa-baby", # Tender/loving approach for newborns
    outfit: "2 Outfits",
    period: ""
  },
   {
    name: "Twin Newborn",
    description: "Luxury newborn photography experience for twin babies. Includes artistic poses, beautiful props, and heirloom-quality editing. Multiple setup changes and family shots included.",
    amount: 200000, # $1200.00
    discount: 0.0,
    duration: 180, # 3 hours for comprehensive session
    included: "18",
    shoot_type: "Twin Newborn",
    icon: "fa-baby", # Tender/loving approach for newborns
    outfit: "3 Outfits",
    period: ""
  }
]

created_count = 0
errors = []

twin_pricing_data.each do |price_data|
  begin
    price = Price.create!(
      name: price_data[:name],
      description: price_data[:description],
      amount: price_data[:amount],
      discount: price_data[:discount],
      duration: price_data[:duration],
      included: price_data[:included],
      shoot_type: price_data[:shoot_type],
      still_valid: true,
      icon: price_data[:icon],
      outfit: price_data[:outfit],
      period: price_data[:period],
      created_at: Time.current,
      updated_at: Time.current
    )

    created_count += 1
    puts "✅ Created: #{price.name} (#{price.shoot_type}) - $#{price.amount/100.0}"

  rescue => e
    error_msg = "❌ Failed to create #{price_data[:name]}: #{e.message}"
    errors << error_msg
    puts error_msg
  end
end

puts "\n📊 TWIN PRICING SUMMARY:"
puts "   Created: #{created_count} new twin pricing options"
puts "   Errors: #{errors.count}"

if errors.any?
  puts "\n🚨 ERRORS:"
  errors.each { |error| puts "   #{error}" }
else
  puts "🎉 All twin pricing options created successfully!"
end

puts "\n👶👶 Available Twin Packages:"
Price.where(still_valid: true).where("name LIKE ?", "%Twin%").each do |price|
  puts "   • #{price.name} - $#{price.amount/100.0} (#{price.duration}min, #{price.included} photos)"
end
