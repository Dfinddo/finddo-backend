# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :orders, dependent: :restrict_with_error
  has_many :orders_as_professional, class_name: "Order", foreign_key: :professional, dependent: :restrict_with_error

  enum user_type: [:admin, :user, :professional]
end
