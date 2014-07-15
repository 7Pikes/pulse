$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

environment = ENV['RACK_ENV']
Bundler.require :default, environment

require 'sqlite3'

Dir[File.expand_path('../../app/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../../app/models/*.rb', __FILE__)].each { |f| require f }

require 'json'
require 'erb'

db = YAML.load(ERB.new(File.read(File.expand_path('../database.yml', __FILE__))).result)[environment]
ActiveRecord::Base.establish_connection(db)
