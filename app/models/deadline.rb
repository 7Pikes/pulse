class Deadline < ActiveRecord::Base

  belongs_to :task

  validates_presence_of :deadline

end
