# lib/tasks/pricing.rake

namespace :pricing do
    desc "Deactivate all prices for a specific shoot_type"
    task :deactivate, [:shoot_type] => :environment do |t, args|
      shoot_type = args[:shoot_type]
      
      if shoot_type.blank?
        puts "❌ Please provide a shoot_type"
        puts "Usage: rails pricing:deactivate[Kiddies]"
        exit
      end
      
      count = Price.where(shoot_type: shoot_type, still_valid: true)
                  .update_all(
                    still_valid: false,
                    updated_at: Time.current
                  )
      
      puts "✅ Deactivated #{count} prices for shoot_type: #{shoot_type}"
      
      # Show remaining active prices for this shoot_type
      remaining = Price.where(shoot_type: shoot_type, still_valid: true).count
      puts "   #{remaining} active prices remaining for #{shoot_type}"
    end
    
    desc "Seed new pricing data"
    task :seed => :environment do
      puts "🌱 Seeding new pricing data..."
      
      pricing_data = [
        {
          name: "Kiddies",
          description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
          amount: 45000,
          discount: 0.0,
          duration: 45,
          included: "5",
          shoot_type: "Kiddies",
          icon: "fa-baby",
          outfit: "1 Outfit",
          period: ""
        },
        {
          name: "Kiddies",
          description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
          amount: 75000,
          discount: 0.0,
          duration: 60,
          included: "8",
          shoot_type: "Kiddies",
          icon: "fa-baby",
          outfit: "2 Outfit",
          period: ""
        },
        {
          name: "Kiddies",
          description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
          amount: 110000,
          discount: 0.0,
          duration: 90,
          included: "12",
          shoot_type: "Kiddies",
          icon: "fa-baby",
          outfit: "3 Outfits",
          period: ""
        },
        {
            name: "Kiddies",
            description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
            amount: 140000,
            discount: 0.0,
            duration: 90,
            included: "15",
            shoot_type: "Kiddies",
            icon: "fa-baby",
            outfit: "4 Outfits",
            period: ""
        },
        {
            name: "Kiddies",
            description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
            amount: 170000,
            discount: 0.0,
            duration: 120,
            included: "18",
            shoot_type: "Kiddies",
            icon: "fa-baby",
            outfit: "5 Outfits",
            period: ""
        },
        
      ]
      
      created_count = 0
      errors = []
      
      pricing_data.each do |price_data|
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
      
      puts "\n📊 SUMMARY:"
      puts "   Created: #{created_count} new prices"
      puts "   Errors: #{errors.count}"
      
      if errors.any?
        puts "\n🚨 ERRORS:"
        errors.each { |error| puts "   #{error}" }
      end
    end
    
    desc "Show current pricing status by shoot_type"
    task :status => :environment do
      puts "📋 Current Pricing Status:"
      puts "=" * 50
      
      shoot_types = Price.distinct.pluck(:shoot_type).compact.sort
      
      shoot_types.each do |shoot_type|
        active_count = Price.where(shoot_type: shoot_type, still_valid: true).count
        inactive_count = Price.where(shoot_type: shoot_type, still_valid: false).count
        
        puts "#{shoot_type.ljust(20)} | Active: #{active_count.to_s.rjust(2)} | Inactive: #{inactive_count}"
        
        # Show active prices
        if active_count > 0
          Price.where(shoot_type: shoot_type, still_valid: true).each do |price|
            puts "  └─ #{price.name} - $#{price.amount/100.0}"
          end
        end
        puts
      end
    end
    
    desc "Deactivate ALL prices (use with caution)"
    task :deactivate_all => :environment do
      print "⚠️  Are you sure you want to deactivate ALL active prices? (y/N): "
      confirmation = STDIN.gets.chomp.downcase
      
      if confirmation == 'y'
        count = Price.where(still_valid: true)
                    .update_all(
                      still_valid: false,
                      updated_at: Time.current
                    )
        
        puts "✅ Deactivated #{count} prices"
      else
        puts "❌ Operation cancelled"
      end
    end
  end