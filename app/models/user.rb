class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, :registerable, :recoverable, :rememberable and :omniauthable
  devise :database_authenticatable, :authentication_keys => [:username]
end
