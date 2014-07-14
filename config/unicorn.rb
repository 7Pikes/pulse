root_path = File.dirname(File.expand_path('../', __FILE__))

worker_processes 1
working_directory root_path

listen 3000

pid "#{root_path}/tmp/daemons/frontend.pid"

stderr_path "#{root_path}/tmp/daemons/frontend.stderr.log"
stdout_path "#{root_path}/tmp/daemons/frontend.stdout.log"
