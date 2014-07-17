require File.expand_path("../config/environment", __FILE__)

Dir[File.expand_path('../app/dispatch/*.rb', __FILE__)].sort.reverse.each { |f| require f }

require 'curb'
require 'jaconda'
require 'mandrill'
require 'securerandom'
require 'time'
require 'goshortener'

credentials = YAML.load_file(File.expand_path('../config/credentials.yml', __FILE__))

Sync.config(credentials["kanbanery"])
Sync.initialize_queue

Chat.config(credentials["jaconda"])
Chat.initialize_queue

Mail.config(credentials["mandrill"])
Mail.initialize_queue

Shortener.config(credentials["shortener"])

environment = ENV['RACK_ENV']

unless environment == 'test' # constrait for rake console
  Delayed::Worker.new.start
end
