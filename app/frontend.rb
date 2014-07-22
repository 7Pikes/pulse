class Frontend < Sinatra::Base

  set :root, File.expand_path('../../', __FILE__)
  set :public_folder, Proc.new { File.join(root, "public") }
  set :views, Proc.new { File.join(root, "app", "views") }

  use ActiveRecord::ConnectionAdapters::ConnectionManagement

  helpers Sinatra::Cookies


  configure do
    if ENV['RACK_ENV'] == 'production'
      cfg = YAML.load_file(File.expand_path('config/credentials.yml', root))["sinatra"]

      set :cookie_options, {domain: cfg["domain"], path: '/'}
    end
  end


  helpers do
    def login!
      return true if ENV['RACK_ENV'] != 'production'

      return true if request.path_info == '/callback'

      auth = OAuth::GitHub.authorization

      cookies[:id] = auth[:session_id]

      redirect to auth[:authorize_path]
    end
  end


  before do
    login! unless cookies[:auth]
  end


  get '/' do
    redirect to '/default'
  end


  get '/default' do
    @users = User.where(
      id: Task.select(:user_id).where("user_id is not null or watcher_id is not null").reorder(nil)
    )

    if params[:id]
      @user = User.find_by_id(params[:id])
      @works = Task.where(user_id: params[:id])
      @watches = Task.where(watcher_id: params[:id])
    end

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :default, :layout => :layout
  end


  get '/all' do
    @users = User.includes(:tasks).where(
      id: Task.select(:user_id).where("user_id is not null or watcher_id is not null").reorder(nil)
    )

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :all, :layout => :layout
  end


  get '/blocked' do
    @users = User.includes(:tasks).where(
      id: Task.select(:user_id).where("user_id is not null and blocked is true").reorder(nil)
    )

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :blocked, :layout => :layout
  end

  get '/blocked_graph' do
    @blocks = BlockedByDays.order("day DESC").limit(14).reverse.map do |b|
      [b.day.strftime("%d/%m"), b.count]
    end

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :blocked_graph, :layout => :layout
  end

  get '/plan' do
    @calendar = Calendar.new

    deadlines = Deadline.where("deadline between ? and ?", @calendar.period(:start),
      @calendar.period(:end)).where(task_id: Task.all).order(:deadline)

    @plan = {}

    deadlines.each do |d|
      @plan[d.deadline.day] ||= []
      @plan[d.deadline.day] << {"title" => d.task.title, "url" => d.task.global_in_context_url}
    end
    
    erb :plan, :layout => :layout
  end


  get '/status' do
    @jobs = Delayed::Job.select(:attempts, :run_at, :locked_at, :queue, :failed_at, :last_error)

    erb :status, :layout => :layout
  end


  get '/callback' do
    redirect to '/403.html' unless cookies[:id] == params[:state]

    cookies.delete(:id)

    token = OAuth::GitHub.get_token(params[:code]) or redirect to '/500.html'

    redirect to '/403.html' unless OAuth::GitHub.validation(token)

    cookies[:auth] = true

    redirect to '/'
  end

end
