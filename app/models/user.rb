# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_one :user_profile_photo, dependent: :destroy

  has_many :orders, dependent: :restrict_with_error
  
  has_many :professional_order, :class_name => 'Order', :foreign_key => 'professional', dependent: :restrict_with_error #profissional que pegou a ordem.
  
  has_many :selected_professional, :class_name => 'Order', :foreign_key => 'selected_professional_id' # para o filtro de profissionais.
  
  has_many :addresses, dependent: :destroy
  
  has_many :sent_chats, :class_name => 'Chat', :foreign_key => 'sender_id'
  has_many :received_chats, :class_name => 'Chat', :foreign_key => 'receiver_id'

  enum user_type: [:admin, :user, :professional]

  validates :email, uniqueness: true
  validates :cellphone, uniqueness: true
  validates :cpf, uniqueness: true
end
