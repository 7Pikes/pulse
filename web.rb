require File.expand_path("../config/environment", __FILE__)

require 'sinatra/base'

server = ::Thin::Server.new("localhost", 4567, Frontend, {})

server.start
