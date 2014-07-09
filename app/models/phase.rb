#encoding: utf-8

class Phase < ActiveRecord::Base

  has_many :tasks

  validates_presence_of :id, :name, :position

  def self.active_phases
    [236472, 236475, 236476, 236478, 326347].join(',')
  end

end
