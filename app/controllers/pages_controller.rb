# require 'rest-client'
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:public_home]
  # skip_after_action :verify_authorized, only: [:public_home]
  # skip_after_action :verify_policy_scoped, only: [:public_home]


  layout 'public', only: [:public_home]

  def public_home
    # authorize :page, :home?
  end

  def home
  end
end
