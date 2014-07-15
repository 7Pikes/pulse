#encoding: utf-8

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

      Task.includes(:user, :phase).where("user_id is not null").each do |task|
        uid = task.user_id

        unless tasks[uid]
          tasks[uid] = {}
          tasks[uid]["work"]  = []
          tasks[uid]["name"]  = task.user.name
          tasks[uid]["email"] = task.user.email
        end

        tasks[uid]["work"] << task.to_pretty_s
      end

      Task.includes(:watcher, :phase).where("watcher_id is not null").each do |task|
        uid = task.watcher_id

        unless tasks[uid]
          tasks[uid] = {}
          tasks[uid]["name"]  = task.watcher.name
          tasks[uid]["email"] = task.watcher.email
        end

        unless tasks[uid]["watch"]
          tasks[uid]["watch"] = []
          tasks[uid]["watch"] << 'Проверяющий:'
        end

        tasks[uid]["watch"] << task.to_pretty_s
      end

      raise TaskError, "Tasks list is empty!" unless tasks.any?

      tasks
    end

  end

end
