#encoding: utf-8

class Blocker < ActiveRecord::Base

  belongs_to :task

  before_save do |blocker|
    blocker.message = '<описание отсутствует>' if blocker.message.empty?
  end

  default_scope { order(:created) }


  def age
    period = Time.now - created

    day_length = 60 * 60 * 24

    (period / day_length).ceil
  end

end
