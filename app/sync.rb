class Sync

  class << self

    def config(config)
      raise ConfigError, "Missing kanbanery section in config/credentials.yml" unless config

      config.each do |key, val|
        instance_eval "@@#{key} = '#{val}'"
      end

      puts "Initialized Kanbanery module"
    end


    def initialize_queue
      return true if Delayed::Job.where(queue: 'sync').count > 0

      Delayed::Job.enqueue Sync.new, {run_at: schedule, queue: 'sync'}
    end


    def schedule(future=false)
      now = Time.now

      plan = {
        this_morning: Time.local(now.year, now.month, now.day, 8, 29, 0),
        this_evening: Time.local(now.year, now.month, now.day, 22, 29, 0),
        next_morning: Time.local(now.year, now.month, (now.day + 1), 8, 29, 0)
      }

      if future
        period = :this_morning if (0..7).to_a.include?(now.hour)
        period ||= :this_evening if (8..21).to_a.include?(now.hour)
        period ||= :next_morning if (22..23).to_a.include?(now.hour)
      else
        period = :this_morning if (0..8).to_a.include?(now.hour)
        period ||= :this_evening if (9..22).to_a.include?(now.hour)
        period ||= :next_morning if [23].include?(now.hour)
      end

      plan[period]
    end


    def ready?
      job = Delayed::Job.where(queue: 'sync').last

      return false unless job

      !!(job.attempts == 0 and (job.run_at > Time.now + 3600))
    end

  end


  def perform
    get_fresh_data and update_storage

    Delayed::Job.enqueue Sync.new, {run_at: Sync.schedule(true), queue: 'sync'}
  rescue => e
    log_error(e)
    raise e
  end


  private

  def http_request(uri)
    Curl::Easy.perform(uri) do |curl|
      curl.headers["X-Kanbanery-ApiToken"] = @@token
    end
  end


  def get_fresh_data

    uri = "https://#{@@host}/api/#{@@api}/projects/#{@@project}/"

    @users = http_request("#{uri}users.json")
    @phases = http_request("#{uri}columns.json")
    @tasks = http_request("#{uri}tasks.json")

    @users = JSON.parse(@users.body)
    @phases = JSON.parse(@phases.body)
    @tasks = JSON.parse(@tasks.body)

    @tasks.each do |task|
      task["movements"] = fetch_task_movements(task["id"])
      task["blockers"] = fetch_task_blokers(task["id"], task["blocked"])
    end

    true
  end


  def fetch_task_movements(task_id)
    uri = "https://#{@@host}/api/#{@@api}/tasks/#{task_id}/events.json"

    events = http_request(uri)
    events = JSON.parse(events.body)

    TaskEvents.refresh

    events.each do |event|
      statement = 'insert into events (name, user_name, column_name, task_title, created_at)' \
        + 'values(?, ?, ?, ?, ?)'

      attrs = event["custom_attributes"]
      created_at = Time.parse(event["created_at"]).to_i

      values = [event["name"], attrs["user_name"], attrs["column_name"], attrs["task_title"], created_at]

      TaskEvents.db.prepare(statement) do |query|
        query.execute(values)
      end
    end

    movements = TaskEvents.db.execute(
      "select * from events where name = 'task_moved' order by created_at"
    )

    return [] unless movements.any?

    movements.map! { |movement| TaskEvents.with_column_names(movement) }

    movements.each_index do |ind|
      next unless movements[ind + 1]

      movements[ind]["age"] = (movements[ind + 1]["created_at"] - movements[ind]["created_at"])
    end

    story = {}

    movements.each do |movement|
      phase_name = movement["column_name"]

      story[phase_name] ||= {}

      # rewriting author if newer exists
      story[phase_name]["user_name"] = movement["user_name"]

      story[phase_name]["raw_age"] ||= 0
      story[phase_name]["raw_age"] += movement["age"].to_i

      story[phase_name]["life_periods"] ||= []

      life_period = [movement["created_at"], movement["created_at"] + movement["age"].to_i]

      next if life_period[0] == life_period[1]

      story[phase_name]["life_periods"] << life_period.map { |stamp| Time.at(stamp).to_time.utc }
    end

    story.keys.map { |key| story[key].merge("column_name" => key) }
  end


  def fetch_task_blokers(task_id, blocked)
    return [] unless blocked

    uri = "https://#{@@host}/api/#{@@api}/tasks/#{task_id}/blockings.json"

    blocks = http_request(uri)
    blocks = JSON.parse(blocks.body)

    buf = []

    blocks.each do |block|
      message = block["blocking_message"]
      message ||= Task.find_by_id(block["blocking_task_id"]).try(:title).to_s

      buf << {message: message, created: block["created_at"]}
    end

    buf
  end


  def update_storage
    User.delete_all if @users.any?
    Phase.delete_all if @phases.any?
    Task.delete_all if @tasks.any?

    store_users!
    store_phases!
    store_tasks!

    store_deadines!
    store_blocks!

    store_blockers!    
    store_tasks_lifecycle!

    true
  end


  def store_users!
    @users.each do |user|
      begin    
        User.create(id: user["id"], email: user["email"], name: user["name"])
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end
  end


  def store_phases!
    @phases.each do |phase|
      begin        
        Phase.create(id: phase["id"], name: phase["name"], position: phase["position"])
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end
  end


  def store_tasks!
    @tasks.each do |task|
      task = handle_task_watcher(task)

      begin
        Task.create(
          id: task["id"],
          title: task["title"],
          description: task["description"],
          global_in_context_url: task["global_in_context_url"],
          phase_id: task["column_id"],
          user_id: task["owner_id"],
          watcher_id: task["watcher_id"],
          blocked: task["blocked"],
          ready_to_pull: task["ready_to_pull"],
          moved_at: task["moved_at"]
        )
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end
  end


  def store_deadines!
    @tasks.each do |task|
      next unless task["deadline"]

      begin
        Deadline.create(task_id: task["id"], deadline: task["deadline"])
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end
  end


  def store_blocks! 

    BlockedByDays.create(
      count: Task.where(blocked: true).count,
      day: Time.now.beginning_of_day.to_s(:db)
    )

  rescue ActiveRecord::RecordNotUnique
  end

  def store_blockers!
    ids = []

    @tasks.each do |task|
      begin
        task["blockers"].each { |blocker| ids << Blocker.anew(blocker.merge(task_id: task["id"])).id }
      rescue
      end
    end

    Blocker.where("id not in (?)", ids).update_all(active: false)
  end

  def store_tasks_lifecycle!
    TaskLifecycle.delete_all

    @tasks.each do |task|
      begin
        next unless Phase.done_phases.include?(task["column_id"])

        programming = task["movements"].find { |movement| movement["column_name"] == "Programming" }
        reviewing = task["movements"].find { |movement| movement["column_name"] == "Reviewing" }
        testing = task["movements"].find { |movement| movement["column_name"] == "Testing" }

        next if !programming and !reviewing and !testing

        # Now we'll gonna reduce time at columns by time that task was blocked

        blockers = Blocker.where(task_id: task["id"])

        block_time_amount = 0
      
        [programming, reviewing, testing].each do |phase|
          next unless phase

          phase["age"] = phase["raw_age"]

          blockers.each do |blocker|
            phase["life_periods"].each do |life_period|

              if blocker.created >= life_period[0] and blocker.created <= life_period[1]
                # If task was blocked INSIDE of period at given column

                block_time = [blocker.updated, life_period[1]].min - life_period[0]
                phase["age"] -= block_time
                block_time_amount += block_time

              elsif blocker.created <= life_period[0] and blocker.updated >= life_period[0]
                # If task was blocked BEFORE of period at given column

                block_time = [blocker.updated, life_period[1]].min - [blocker.created, life_period[0]].max
                phase["age"] -= block_time
                block_time_amount += block_time

              end

            end
          end

        end

        TaskLifecycle.create(
          task_id:      task["id"],
          programming:  (programming["age"] if programming),
          reviewing:    (reviewing["age"] if reviewing),
          testing:      (testing["age"] if testing),
          blocked:       block_time_amount
        )
      rescue => e
        puts e.class
        puts e.message
      end
    end
  end


  def handle_task_watcher(task)
    movement = task["movements"][-1]

    return task unless movement    

    phase_name = movement["column_name"]

    return task unless %w(Testing Reviewing).include?(phase_name)
    return task unless Phase.find_by_id(task["column_id"]).name == phase_name

    user = User.find_by_name(movement["user_name"])
    task["watcher_id"] = user.id

    task
  end

end
