class TaskLifecycle < ActiveRecord::Base

  belongs_to :task

  default_scope { order(:task_id) }

  def age
    day_length = 60 * 60 * 24

    {
      programming: (programming / day_length).ceil,
      reviewing: (reviewing / day_length).ceil,
      testing: (testing / day_length).ceil
    }
  end

end
