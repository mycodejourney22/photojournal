# require 'rest-client'
class PagesController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def home
  end
end
