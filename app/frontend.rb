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

    erb :default, :layout => :layout
  end

  get '/blocked' do
    erb :blocked, :layout => :layout
  end

end
