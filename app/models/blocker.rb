#encoding: utf-8

class Blocker < ActiveRecord::Base

  belongs_to :task

  before_save do |blocker|
    blocker.message = '<описание отсутствует>' if blocker.message.empty?
  end

  default_scope { order(:created) }


  def self.anew(args)
    one = where(
      task_id: args[:task_id],
      message: args[:message],
      active: true
    ).last

    one ||= new(args)

    one.active = true
    one.updated = Time.now.beginning_of_day.to_s(:db)
    one if one.save    
  end

end
