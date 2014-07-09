class PulseDispatch

  class << self

    def schedule
      now = Time.now

      if now.hour > 8
        Time.local(now.year, now.month, (now.day + 1), 9, 01, 0)
      else
        Time.local(now.year, now.month, now.day, 9, 01, 0)
      end
    end


    def get_tasks_list
      tasks = {}

      Task.includes(:user, :phase).each do |task|
        unless tasks[task.user_id]
          tasks[task.user_id] = {}
          tasks[task.user_id]["name"] = task.user.name
          tasks[task.user_id]["email"] = task.user.email
          tasks[task.user_id]["titles"] = []
        end

        tasks[task.user_id]["titles"] << task.to_pretty_s
      end

      raise TaskError, "Tasks list is empty!" unless tasks.any?

      tasks
    end

  end

end
