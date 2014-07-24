#encoding: utf-8

class Chat < PulseDispatch

  class << self

    def config(config)
      raise ConfigError, "Missing jaconda section in config/credentials.yml" unless config

      Jaconda::Notification.authenticate(config.symbolize_keys)

      @@sender = "Pulse"

      puts "Initialized Jaconda module"
    end


    def initialize_queue
      return true if Delayed::Job.where(queue: 'chat').count > 0

      Delayed::Job.enqueue Chat.new, {run_at: schedule, queue: 'chat'}
    end


    def get_tasks_list
      # Lists only blocked tasks

      tasks = {}

      Task.includes(:user, :phase).where("user_id is not null and blocked is true").each do |task|
        uid = task.user_id

        unless tasks[uid]
          tasks[uid] = {}
          tasks[uid]["work"]  = []
          tasks[uid]["name"]  = task.user.name
          tasks[uid]["email"] = task.user.email
        end

        tasks[uid]["work"] << task.make_pretty(:blocked)
      end

      raise TaskError, "Tasks list is empty!" unless tasks.any?

      tasks
    end

  end


  def perform
    raise SyncNotReady, "Synchronization is still working" unless Sync.ready?

    compile_brief and dispatch_brief
    
    Delayed::Job.enqueue Chat.new, {run_at: Chat.schedule, queue: 'chat'}
  rescue => e
    log_error(e)
    raise e
  end


  private


  def compile_brief
    tasks = Chat.get_tasks_list

    buf = []

    buf << "Доброе утро, 7пайкс!"
    buf << "Перед первой чашкой кофе обратите внимание на следующие заблокированные задачи:"
    buf << " "

    tasks.each do |key, val|
      buf << "Задачи #{val["name"]}:"
      val["work"].each { |title| buf << title }
      buf << " "
    end

    @brief = buf.join("\n")

    true
  end


  def dispatch_brief
    Jaconda::Notification.notify(text: @brief, sender_name: @@sender)
  end

end
