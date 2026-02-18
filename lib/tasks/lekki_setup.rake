# lib/tasks/lekki_setup.rake
#
# Run with: rails lekki:setup
# This will create the Lekki studio and copy all existing prices at 1.5x

namespace :lekki do
  desc "Create Lekki studio"
  task create_studio: :environment do
    puts "🏢 Creating Lekki Studio..."

    studio = Studio.find_or_create_by!(location: "Lekki") do |s|
      s.name = "363 Photography Lekki"
      s.address = "Lekki Phase 1, Lagos"  # Update with actual address
      s.phone = "07048289684"              # Update with actual phone
      s.email = "363photography3@gmail.com" # Update with actual email
      s.active = true
    end

    puts "✅ Lekki Studio created/found with ID: #{studio.id}"
    studio
  end

  desc "Create Lekki-specific pricing (1.5x of regular prices)"
  task create_pricing: :environment do
    puts "💰 Creating Lekki-specific pricing (1.5x multiplier)..."

    lekki_studio = Studio.find_by(location: "Lekki")

    unless lekki_studio
      puts "❌ Lekki studio not found! Run 'rails lekki:create_studio' first."
      exit 1
    end

    # Get all active global prices (prices without a studio_id)
    global_prices = Price.where(studio_id: nil, still_valid: true)

    if global_prices.empty?
      puts "❌ No global prices found to copy!"
      exit 1
    end

    puts "📋 Found #{global_prices.count} global prices to copy..."

    created_count = 0
    skipped_count = 0
    errors = []

    global_prices.each do |original_price|
      # Check if Lekki price already exists for this shoot_type and outfit
      existing = Price.find_by(
        studio_id: lekki_studio.id,
        shoot_type: original_price.shoot_type,
        outfit: original_price.outfit,
        still_valid: true
      )

      if existing
        puts "⏭️  Skipped: #{original_price.shoot_type} - #{original_price.outfit} (already exists)"
        skipped_count += 1
        next
      end

      begin
        # Calculate new amount (1.5x)
        new_amount = (original_price.amount * 1.5).round(0)

        # Create Lekki version
        lekki_price = Price.create!(
          name: original_price.name,
          description: original_price.description,
          amount: new_amount,
          discount: original_price.discount,
          duration: original_price.duration,
          included: original_price.included,
          shoot_type: original_price.shoot_type,
          still_valid: true,
          icon: original_price.icon,
          outfit: original_price.outfit,
          period: original_price.period,
          studio_id: lekki_studio.id
        )

        created_count += 1
        puts "✅ Created: #{lekki_price.shoot_type} - #{lekki_price.outfit} | ₦#{original_price.amount.to_i} → ₦#{new_amount.to_i}"

      rescue => e
        error_msg = "❌ Failed to create #{original_price.shoot_type} #{original_price.outfit}: #{e.message}"
        errors << error_msg
        puts error_msg
      end
    end

    puts "\n📊 SUMMARY:"
    puts "   Created: #{created_count} Lekki prices"
    puts "   Skipped: #{skipped_count} (already existed)"
    puts "   Errors: #{errors.count}"

    if errors.any?
      puts "\n🚨 ERRORS:"
      errors.each { |error| puts "   #{error}" }
    end
  end

  desc "Full Lekki setup (studio + pricing at 1.5x)"
  task setup: :environment do
    Rake::Task["lekki:create_studio"].invoke
    Rake::Task["lekki:create_pricing"].invoke

    puts "\n🎉 Lekki setup complete!"
    puts "\nNext steps:"
    puts "1. Update the Lekki studio address, phone, and email"
    puts "2. Review and adjust any prices if needed"
  end

  desc "Show Lekki pricing comparison with regular prices"
  task status: :environment do
    lekki_studio = Studio.find_by(location: "Lekki")

    unless lekki_studio
      puts "❌ Lekki studio not found. Run 'rails lekki:setup' first."
      exit 1
    end

    puts "🏢 Lekki Studio: #{lekki_studio.name}"
    puts "   Address: #{lekki_studio.address}"
    puts "   Phone: #{lekki_studio.phone}"
    puts "   Active: #{lekki_studio.active?}"

    puts "\n💰 Lekki Pricing vs Regular Pricing:"
    puts "=" * 80
    puts "#{'Shoot Type'.ljust(18)} | #{'Outfit'.ljust(12)} | #{'Regular'.rjust(12)} | #{'Lekki'.rjust(12)} | #{'Diff'.rjust(8)}"
    puts "-" * 80

    Price.where(studio_id: nil, still_valid: true).order(:shoot_type, :amount).each do |regular|
      lekki = Price.find_by(
        studio_id: lekki_studio.id,
        shoot_type: regular.shoot_type,
        outfit: regular.outfit,
        still_valid: true
      )

      if lekki
        diff = ((lekki.amount - regular.amount) / regular.amount * 100).round(0)
        puts "#{regular.shoot_type.ljust(18)} | #{regular.outfit.to_s.ljust(12)} | ₦#{regular.amount.to_i.to_s.rjust(10)} | ₦#{lekki.amount.to_i.to_s.rjust(10)} | +#{diff}%"
      else
        puts "#{regular.shoot_type.ljust(18)} | #{regular.outfit.to_s.ljust(12)} | ₦#{regular.amount.to_i.to_s.rjust(10)} | #{'(missing)'.rjust(12)} |"
      end
    end
  end

  desc "Update Lekki prices to 1.5x of current regular prices"
  task update_pricing: :environment do
    lekki_studio = Studio.find_by(location: "Lekki")

    unless lekki_studio
      puts "❌ Lekki studio not found!"
      exit 1
    end

    puts "🔄 Updating Lekki prices to 1.5x of regular prices..."

    updated_count = 0

    Price.where(studio_id: lekki_studio.id, still_valid: true).each do |lekki_price|
      # Find matching regular price
      regular = Price.find_by(
        studio_id: nil,
        shoot_type: lekki_price.shoot_type,
        outfit: lekki_price.outfit,
        still_valid: true
      )

      if regular
        new_amount = (regular.amount * 1.5).round(0)
        old_amount = lekki_price.amount

        if old_amount != new_amount
          lekki_price.update!(amount: new_amount)
          puts "✅ Updated: #{lekki_price.shoot_type} - #{lekki_price.outfit} | ₦#{old_amount.to_i} → ₦#{new_amount.to_i}"
          updated_count += 1
        end
      end
    end

    puts "\n📊 Updated #{updated_count} Lekki prices"
  end

  desc "Delete all Lekki-specific prices (use with caution)"
  task clear_pricing: :environment do
    lekki_studio = Studio.find_by(location: "Lekki")

    unless lekki_studio
      puts "❌ Lekki studio not found!"
      exit 1
    end

    count = Price.where(studio_id: lekki_studio.id).count

    print "⚠️  Are you sure you want to delete #{count} Lekki prices? (y/N): "
    confirmation = STDIN.gets.chomp.downcase

    if confirmation == 'y'
      deleted = Price.where(studio_id: lekki_studio.id).destroy_all
      puts "✅ Deleted #{deleted.count} Lekki prices"
    else
      puts "❌ Operation cancelled"
    end
  end
end
