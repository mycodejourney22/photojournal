namespace :data_migration do
    desc "Associate existing appointments with studios"
    task associate_appointments_with_studios: :environment do
      studios = Studio.all.index_by { |s| s.location.downcase }
      
      puts "Starting to associate #{Appointment.count} appointments with studios..."
      
      Appointment.find_each do |appointment|
        studio = studios[appointment.location.downcase]
        if studio
          appointment.update_column(:studio_id, studio.id)
          print "."
        else
          puts "\nWarning: No studio found for location '#{appointment.location}' (Appointment ID: #{appointment.id})"
        end
      end
      
      puts "\nCompleted!"
    end

    task normalize_locations: :environment do
        # Define mapping rules for normalization
        location_mapping = {
          /surulere|bode thomas/i => "Surulere",
          /ikeja|adeniyi jones/i => "Ikeja",
          /ajah|ilaje|lekki epe/i => "Ajah"
        }
        
        puts "Starting location normalization for #{Appointment.count} appointments..."
        
        normalized_count = 0
        no_match_count = 0
        
        # Process appointments in batches to avoid memory issues
        Appointment.find_each do |appointment|
          original_location = appointment.location.to_s
          normalized_location = nil
          
          # Try to find matching pattern
          location_mapping.each do |pattern, standard_name|
            if original_location =~ pattern
              normalized_location = standard_name
              break
            end
          end
          
          if normalized_location && original_location != normalized_location
            appointment.update_column(:location, normalized_location)
            puts "Normalized: '#{original_location}' -> '#{normalized_location}'"
            normalized_count += 1
          elsif normalized_location.nil?
            puts "No match for: '#{original_location}' (Appointment ID: #{appointment.id})"
            no_match_count += 1
          end
        end
        
        puts "Normalization completed!"
        puts "#{normalized_count} locations normalized"
        puts "#{no_match_count} locations with no matching pattern"
      end
      
    desc "Associate existing appointments with studios after normalization"
    task associate_appointments_with_studios: :environment do
    puts "Make sure you've run the normalize_locations task first!"
    puts "Starting to associate #{Appointment.count} appointments with studios..."
    
    # Build a map of normalized location names to studio IDs
    studios_by_location = Studio.all.index_by { |s| s.location }
    
    updated = 0
    not_matched = 0
    
    Appointment.find_each do |appointment|
        location = appointment.location.to_s
        
        if studios_by_location[location]
        appointment.update_column(:studio_id, studios_by_location[location].id)
        print "."
        updated += 1
        else
        puts "\nWarning: No studio found for location '#{location}' (Appointment ID: #{appointment.id})"
        not_matched += 1
        end
    end
    
    puts "\nCompleted! Associated #{updated} appointments with studios."
    puts "#{not_matched} appointments could not be matched to a studio."
    end
  end