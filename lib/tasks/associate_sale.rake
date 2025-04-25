namespace :data_migration do
    desc "Normalize sale locations before studio association"
    task normalize_sale_locations: :environment do
      # Define normalization rules
      normalization_map = {
        "Surulere" => "Surulere",
        "surulere" => "Surulere",
        "Ikeja" => "Ikeja",
        "ikeja" => "Ikeja",
        "Ajah" => "Ajah",
        "ajah" => "Ajah",
        "Admin" => "General",
        "general" => "General" # You might want to map this to something specific
      }
      
      # Get counts of each location value in the database
      puts "Current sale location distribution:"
      Sale.group(:location).count.each do |location, count|
        puts "  '#{location}': #{count} sales"
      end
      
      # Process each location value
      puts "\nNormalizing sale locations..."
      updated = 0
      
      normalization_map.each do |original, normalized|
        count = Sale.where(location: original).count
        if count > 0
          Sale.where(location: original).update_all(location: normalized)
          puts "  Normalized '#{original}' to '#{normalized}' (#{count} records)"
          updated += count
        end
      end
      
      # Handle any unmapped values
      unmapped = Sale.where.not(location: normalization_map.values).pluck(:location).uniq
      if unmapped.any?
        puts "\nWarning: Found unmapped location values:"
        unmapped.each do |loc|
          count = Sale.where(location: loc).count
          puts "  '#{loc}': #{count} sales"
        end
      end
      
      puts "\nNormalization completed! Updated #{updated} sales."
      puts "Current distribution after normalization:"
      Sale.group(:location).count.each do |location, count|
        puts "  '#{location}': #{count} sales"
      end
    end
    
    desc "Associate sales with studios after normalization"
    task associate_sales_with_studios: :environment do
      puts "Make sure you've run the normalize_sale_locations task first!"
      puts "Starting to associate sales with studios..."
      
      # Create direct mapping from normalized location to studio
      studio_mapping = {
        "Surulere" => Studio.find_by("location ILIKE ?", "%surulere%")&.id,
        "Ikeja" => Studio.find_by("location ILIKE ?", "%ikeja%")&.id,
        "Ajah" => Studio.find_by("location ILIKE ?", "%ajah%")&.id,
        "General" => Studio.first&.id # You might want to use a specific studio for "general"
      }
      
      # Show the mapping
      puts "Using the following mapping:"
      studio_mapping.each do |location, studio_id|
        studio = Studio.find_by(id: studio_id)
        puts "  '#{location}' -> Studio ID: #{studio_id} (#{studio&.location || 'Not found'})"
      end
      
      # Update sale records
      updated = 0
      skipped = 0
      
      Sale.find_each do |sale|
        location = sale.location
        studio_id = studio_mapping[location]
        
        if studio_id.present?
          sale.update_column(:studio_id, studio_id)
          updated += 1
          print "." if updated % 100 == 0
        else
          puts "\nWarning: No studio mapping for location '#{location}' (Sale ID: #{sale.id})"
          skipped += 1
        end
      end
      
      puts "\nCompleted! Updated #{updated} sales with studio_id."
      puts "Skipped #{skipped} sales that couldn't be mapped."
    end
end