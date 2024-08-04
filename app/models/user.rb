class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  ROLES = %w[admin ikeja surulere ajah social]

  validates :role, presence: true, inclusion: { in: ROLES }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def admin?
    self.role == 'admin'
  end

  def ikeja?
    self.role = 'ikeja'
  end

  def not_social?
    self.role != 'social'
  end

  def social?
    self.role = 'social'
  end
end
