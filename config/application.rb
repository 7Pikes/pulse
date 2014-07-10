$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

environment = ENV['RACK_ENV']
Bundler.require :default, environment

Dir[File.expand_path('../../app/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../../app/dispatch/*.rb', __FILE__)].sort.reverse.each { |f| require f }
Dir[File.expand_path('../../app/models/*.rb', __FILE__)].each { |f| require f }

require 'curb'
require 'json'

require 'jaconda'
# require 'net/smtp'
require 'mandrill'
require 'securerandom'

require 'erb'

db = YAML.load(ERB.new(File.read(File.expand_path('../database.yml', __FILE__))).result)[environment]
ActiveRecord::Base.establish_connection(db)

credentials = YAML.load_file(File.expand_path('../credentials.yml', __FILE__))

# Sync.config(credentials["kanbanery"])
# Sync.initialize_queue

# Chat.config(credentials["jaconda"])
# Chat.initialize_queue

# Mail.config(credentials["mandrill"])
# Mail.initialize_queue

require 'sinatra/base'

unless environment == 'test'
#   Delayed::Worker.new.start
  Frontend.run!
end
