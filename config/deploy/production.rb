role :app, %w{pulse@198.199.127.168}
role :db,  %w{pulse@198.199.127.168}

server '198.199.127.168', user: 'pulse', roles: %w{app db}
