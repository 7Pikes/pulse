#encoding: utf-8

class PulseDispatch

  class << self

    def schedule
      now = Time.now

      plan = 
        if now.hour > 8
          Time.local(now.year, now.month, (now.day + 1), 9, 01, 0)
        else
          Time.local(now.year, now.month, now.day, 9, 01, 0)
        end

      day_length = 86400

      plan += (2 * day_length) if plan.saturday?
      plan += day_length if plan.sunday?

      plan
    end


    def get_tasks_list
      tasks = {}

      Task.includes(:user, :phase).where("user_id is not null").each do |task|
        uid = task.user_id

        unless tasks[uid]
          tasks[uid] = {}
          tasks[uid]["name"]  = task.user.name
          tasks[uid]["email"] = task.user.email
        end

        tasks[uid]["work"] = [] unless tasks[uid]["work"]

        tasks[uid]["work"] << task.make_pretty(:array)
      end

      Task.includes(:watcher, :phase).where("watcher_id is not null").each do |task|
        uid = task.watcher_id

        unless tasks[uid]
          tasks[uid] = {}
          tasks[uid]["name"]  = task.watcher.name
          tasks[uid]["email"] = task.watcher.email
        end

        tasks[uid]["watch"] = [] unless tasks[uid]["watch"]

        tasks[uid]["watch"] << task.make_pretty(:array)
      end

      raise TaskError, "Tasks list is empty!" unless tasks.any?

      tasks
    end

  end

end
