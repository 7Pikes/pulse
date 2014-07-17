module OAuth
  class GitHub

    # Here we have 3 steps:
    # 1. Github authorization part one: check the user, get an auth code.
    # 2. Github authorization part two: get an API access token.
    # 3. API conversation: get user's data, check user's membership.


    class << self

      def config(config)
        raise ConfigError, "Missing github section in config/credentials.yml" unless config

        config.each do |key, val|
          instance_eval "@@#{key} = '#{val}'"
        end

        puts "Initialized GitHub module"
      end


      def authorization
        session_id = SecureRandom.hex

        {
          session_id: session_id,
          authorize_path: "#{@@web_addr}/login/oauth/authorize?client_id=#{@@client_id}&state=#{session_id}"
        }
      end


      def get_token(auth_code)
        params = {client_id: @@client_id, client_secret: @@client_secret, code: auth_code}

        response = http_post("#{@@web_addr}/login/oauth/access_token", params)

        response["access_token"]
      end


      def validation(access_token)
        response = http_get("#{@@api_addr}/user", {access_token: access_token})

        login = response["login"] or return false

        response = http_get("#{@@api_addr}/orgs/#{@@organisation}/members", {access_token: access_token})

        response.map { |member| member["login"] }.include?(login)

      rescue
        false
      end


      private


      def http_post(uri, params={})
        response = Curl.post(uri, params) do |curl|
          curl.headers["Accept"] = 'application/json'
          curl.headers["User-Agent"] = "7Pikes Pule Bot"
        end

        JSON.parse(response.body)
      end


      def http_get(uri, params={})
        response = Curl.get(uri, params) do |curl|
          curl.headers["Accept"] = 'application/json'
          curl.headers["User-Agent"] = "7Pikes Pule Bot"
        end

        JSON.parse(response.body)
      end

    end

  end
end
