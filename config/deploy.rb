require 'sshkit/dsl'

# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'Pulse'
set :repo_url, 'https://github.com/7Pikes/pulse.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

set :branch, 'production'

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/pulse'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5


namespace :pulse do
  desc 'Start daemon'
  task :start do
    on roles(:app) do
      execute "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/pulse start"
    end
  end

  desc 'Stop daemon'
  task :stop do
    on roles(:app) do
      execute "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/pulse stop"
    end
  end

  desc 'Status of daemon'
  task :status do
    on roles(:app) do
      capture "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/pulse status"
    end
  end
end


namespace :frontend do
  desc 'Start web server'
  task :start do
    on roles(:app) do
      execute "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/frontend start"
    end
  end

  desc 'Stop web server'
  task :stop do
    on roles(:app) do
      execute "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/frontend stop"
    end
  end

  desc 'Status of web server'
  task :status do
    on roles(:app) do
      capture "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && RACK_ENV=production bin/frontend status"
    end
  end
end


namespace :deploy do
  desc 'Upload local config files: config/database.yml and config/credentials.yml'
  task :upload_configs do
    on roles(:app) do
      upload! "config/database.yml", "#{deploy_to}/current/config/database.yml"
      upload! "config/credentials.yml", "#{deploy_to}/current/config/credentials.yml"      
    end
  end

  desc 'Run bundle install'
  task :bundle_install do
    on roles(:app) do
      capture "source ~/.rvm/scripts/rvm && cd #{deploy_to}/current && bundle install"
    end
  end

  desc 'Clear temporary files'
  task :clear_temp do
    on roles(:app) do
      capture "cd #{deploy_to}/current && rm tmp/daemons/*"
    end
  end
end
