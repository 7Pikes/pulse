require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end


require 'rake'


desc "Check the application."
task :environment do
  require File.expand_path("../config/environment", __FILE__)
end


desc "Run pry console."
task :console do
  require 'pry'

  ENV['RACK_ENV'] = 'test'
  Rake::Task["environment"].invoke
  
  binding.pry
end


require 'erb'
require 'active_record'


namespace :db do

  task :load_config do
    ActiveRecord::Base.establish_connection(db_config.except(:database))
  end
  

  desc "Create the database and then run migrations."
  task :setup => :load_config do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end
  

  desc "Run migrations."
  task :migrate do
    ActiveRecord::Base.establish_connection(db_config)

    ActiveRecord::Migrator.migrate(
      ActiveRecord::Migrator.migrations_paths, 
      ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    )
  end
  

  desc 'Drop the database.'
  task :drop => :load_config do
    ActiveRecord::Base.connection.drop_database(db_config[:database])
  end
  

  desc 'Create the database.'
  task :create => :load_config do
    options = {charset: 'utf8', collation: 'utf8_unicode_ci'}
    ActiveRecord::Base.connection.create_database(db_config[:database], options)
  end
  
end


def db_config
  environment = ENV['RACK_ENV'] || 'development'
  config = File.read(File.expand_path('../config/database.yml', __FILE__))

  YAML.load(ERB.new(config).result)[environment].symbolize_keys
end
