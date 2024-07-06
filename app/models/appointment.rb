class Appointment < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :sales, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true
  has_one :photo_shoot
  validates :name, presence: true
  validates :email, presence: true
  validates :name, presence: true
end
