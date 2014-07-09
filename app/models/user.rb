class User < ActiveRecord::Base

  has_many :tasks

  validates_presence_of :id, :email, :name

end
