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

    tasks.each do |key, val|
      buf << "Задачи #{val["name"]}:"
      val["titles"].each { |title| buf << title }
      buf << ' '      
    end

    @brief = buf.join("\n")

    # split_to_pages

    true
  end


  # def split_to_pages(num=1800)
  #   pages = []

  #   position = 0

  #   loop do
  #     caret = @brief.rindex("\n", num + position)
  #     break if caret <= position

  #     pages << @brief[position..caret]
  #     position = caret + 1
  #   end

  #   @brief = pages
  # end


  def dispatch_brief    
    # @brief.each do |chuck|
    #   Jaconda::Notification.notify(text: chuck, sender_name: @@sender)
    # end

    Jaconda::Notification.notify(text: @brief, sender_name: @@sender)
  end

end
