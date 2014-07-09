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


  def get_fresh_data

    uri = "https://#{@@host}/api/#{@@api}/projects/#{@@project}/"

    @users = Curl::Easy.perform("#{uri}users.json") do |curl| 
      curl.headers["X-Kanbanery-ApiToken"] = @@token
    end

    @phases = Curl::Easy.perform("#{uri}columns.json") do |curl| 
      curl.headers["X-Kanbanery-ApiToken"] = @@token
    end

    @tasks = Curl::Easy.perform("#{uri}tasks.json") do |curl| 
      curl.headers["X-Kanbanery-ApiToken"] = @@token
    end

    @users = JSON.parse(@users.body)
    @phases = JSON.parse(@phases.body)
    @tasks = JSON.parse(@tasks.body)

    true
  end


  def update_storage
    User.delete_all if @users.any?
    Phase.delete_all if @phases.any?
    Task.delete_all if @tasks.any?


    @users.each do |user|
      begin    
        User.create(id: user["id"], email: user["email"], name: user["name"])
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end

    @phases.each do |phase|
      begin        
        Phase.create(id: phase["id"], name: phase["name"], position: phase["position"])
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end

    @tasks.each do |task|
      begin
        Task.create(
          id: task["id"],
          title: task["title"],
          description: task["description"],
          global_in_context_url: task["global_in_context_url"],
          phase_id: task["column_id"],
          user_id: task["owner_id"],
          blocked: task["blocked"],
          ready_to_pull: task["ready_to_pull"],
          moved_at: task["moved_at"]
        )
      rescue ActiveRecord::RecordNotUnique => e
        puts e.class
        puts e.message
      end
    end

    true
  end

end
