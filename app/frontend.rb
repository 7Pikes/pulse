class Frontend < Sinatra::Base

  use ActiveRecord::ConnectionAdapters::ConnectionManagement

  require 'pry'

  set :root, File.expand_path('../../', __FILE__)
  set :public_folder, Proc.new { File.join(root, "public") }
  set :views, Proc.new { File.join(root, "app", "views") }

  # set :server, 'thin'
  set :server, 'webrick'
  set :port, 4567


  get '/' do
    redirect to '/default'
  end


  get '/default' do
    @users = User.all

    if params[:id]
      @user = User.find_by_id(params[:id])
      @tasks = Task.where(user_id: params[:id])
    end

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :default, :layout => :layout
  end


  get '/blocked' do
    @users = User.where(id: Task.select(:user_id).where(blocked: true).reorder(nil))

    if params[:id]
      @user = User.find_by_id(params[:id])
      @tasks = Task.where(user_id: params[:id])
    end

    @health = Delayed::Job.where("last_error is not null").count == 0

    erb :blocked, :layout => :layout
  end


  get '/status' do
    @jobs = Delayed::Job.select(:attempts, :run_at, :locked_at, :queue, :failed_at, :last_error)

    erb :status, :layout => :layout
  end

end
