class ConfigError < StandardError; end
class SyncNotReady < StandardError; end
class TaskError < StandardError; end


def log_error(e)
  divider = e.message.to_s.length + 30
  divider = 80 if divider > 80

  puts ""
  puts "-" * divider
  puts "Error class:  #{e.class}"
  puts "Messsage:     #{e.message}"
  puts "Timestamp:    #{Time.now}"
  puts ""
  puts e.backtrace
end
