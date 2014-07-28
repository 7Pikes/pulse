#encoding: utf-8

class Mail < PulseDispatch

  class << self

    def config(config)
      raise ConfigError, "Missing mandrill section in config/credentials.yml" unless config

      config.each do |key, val|
        instance_eval "@@#{key} = '#{val}'"
      end

      puts "Initialized Mandrill module"
    end


    def schedule
      # 9-minute delay caused by GoShortener limitations
      super + 540
    end


    def initialize_queue
      return true if Delayed::Job.where(queue: 'mail').count > 0

      Delayed::Job.enqueue Mail.new, {run_at: schedule, queue: 'mail'}
    end

  end


  def perform
    raise SyncNotReady, "Synchronization is still working" unless Sync.ready?

    compile_reminder and dispatch_reminder
    
    Delayed::Job.enqueue Mail.new, {run_at: Mail.schedule, queue: 'mail'}
  rescue => e
    log_error(e)
    raise e
  end


  private


  def compile_reminder
    tasks = Mail.get_tasks_list

    @mailing = []

    tasks.each do |key, val|
      buf = {}
      buf["man"]      =  val["name"]
      buf["receiver"] =  val["email"]
      buf["message"]  =  ''

      if val["work"]

        buf["message"]  += <<-EOS
        <p>Товарищ! Убедись, что у тебя нет заблокированных задач.</p>
        <strong>Задачи:</strong>
        <br/>
        <table>
          <thead>
            <tr>
              <th>Блокировка</th>
              <th>Заголовок</th>
              <th>Статус</th>
              <th>С какого числа</th>
            </tr>
          </thead>
          <tbody>
        EOS

        val["work"].each do |task|
          buf["message"] += <<-EOS
              <tr>
                <td>#{task[0] ? 'есть' : 'нет'}</td>
                <td><a href="#{task[2]}" target="_blank">#{task[1]}</a></td>
                <td>#{task[3]}</td>
                <td>#{task[4]}</td>
              </tr>
          EOS
        end

        buf["message"] += <<-EOS
          </tbody>
        </table>
        <br/>
        <br/>
        EOS

      end


      if val["watch"]

        buf["message"]  += <<-EOS
        <strong>Наблюдаемые задачи:</strong>
        <br/>
        <table>
          <thead>
            <tr>
              <th>Блокировка</th>
              <th>Заголовок</th>
              <th>Статус</th>
              <th>С какого числа</th>
            </tr>
          </thead>
          <tbody>
        EOS

        val["watch"].each do |task|
          buf["message"] += <<-EOS
              <tr>
                <td>#{task[0] ? 'есть' : 'нет'}</td>
                <td><a href="#{task[2]}" target="_blank">#{task[1]}</a></td>
                <td>#{task[3]}</td>
                <td>#{task[4]}</td>
              </tr>
          EOS
        end

        buf["message"] += <<-EOS
          </tbody>
        </table>
        <br/>
        <br/>
        EOS

      end

      @mailing << buf
    end

    prepare_messages_bodies

    true
  end


  def prepare_messages_bodies
    @mailing.map! do |mail|

      message = {
        subject: @@subject,
        html: mail["message"],
        to: [ {email: mail["receiver"], name: mail["man"]} ],
        from_email: @@sender
      }

      message
    end
  end


  def dispatch_reminder
    mandrill = Mandrill::API.new @@token

    @mailing.each do |message|
      mandrill.messages.send message 
    end
  end

end
