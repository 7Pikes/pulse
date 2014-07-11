require File.expand_path("../config/environment", __FILE__)

require 'sinatra/base'

server = ::Thin::Server.new("198.199.127.168", 3000, Frontend, {})

server.start
