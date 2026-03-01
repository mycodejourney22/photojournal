class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  ROLES = %w[admin ikeja surulere ajah lekki social super_admin manager customer_service user]

  validates :role, presence: true, inclusion: { in: ROLES }
  belongs_to :studio, optional: true

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def admin?
    role == 'admin'
  end

  def super_admin?
    role == 'super_admin'
  end

  def ikeja?
    role == 'ikeja'
  end

  def lekki?
    role == 'lekki'
  end

  def not_social?
    role != 'social'
  end

  def social?
    role == 'social'
  end

  def manager?
    role == 'manager'
  end

  def customer_service?
    role == 'customer_service'
  end

  def studio_location
    studio&.location&.downcase
  end

  # Check if user is a studio manager (has studio assigned)
  def studio_manager?
    manager? && studio_id.present?
  end

  attr_accessor :skip_password_validation

  def generate_password_setup_token!
    token = SecureRandom.hex(20)
    update_columns(
      password_setup_token: token,
      password_setup_sent_at: Time.current
    )
    token
  end

  protected

  def password_required?
    return false if skip_password_validation
    super
  end
end
