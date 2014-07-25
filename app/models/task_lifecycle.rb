class TaskLifecycle < ActiveRecord::Base

  default_scope { order(:task_id) }

  def task
    Task.unscoped.find_by_id(task_id)
  end

  def age(attribute)
    day_length = 60 * 60 * 24

    case attribute
    when :programming
      (programming.to_i / day_length).ceil
    when :reviewing
      (reviewing.to_i / day_length).ceil
    when :testing
      (testing.to_i / day_length).ceil
    end
  end

end
