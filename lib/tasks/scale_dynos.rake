namespace :heroku do
  desc "Scale dynos to Standard-2X"
  task scale_to_standard_2x: :environment do
    app_name = "photologger"  # Replace with your Heroku app name
    command = "heroku ps:scale web=1:Standard-2X --app #{app_name}"

    puts "Scaling app #{app_name} to Standard-2X..."
    system(command)

    if $?.success?
      puts "Successfully scaled to Standard-2X."
    else
      puts "Failed to scale to Standard-2X."
    end
  end

  desc "Scale dynos to Standard-1X"
  task scale_to_standard_1x: :environment do
    app_name = "photologger"  # Replace with your Heroku app name
    command = "heroku ps:scale web=1:Standard-1X --app #{app_name}"

    puts "Scaling app #{app_name} to Standard-1X..."
    system(command)

    if $?.success?
      puts "Successfully scaled to Standard-1X."
    else
      puts "Failed to scale to Standard-1X."
    end
  end


  desc "Scale dynos to Basic tier (Free or Hobby)"
  task scale_to_basic: :environment do
    app_name = "photologger"  # Replace with your Heroku app name
    command = "heroku ps:scale web=1:Basic --app #{app_name}"  # Use Free if you prefer that tier

    puts "Scaling app #{app_name} to Basic tier..."
    system(command)

    if $?.success?
      puts "Successfully scaled to Basic tier."
    else
      puts "Failed to scale to Basic tier."
    end
  end
end
