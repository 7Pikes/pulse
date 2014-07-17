module Shortener

  class << self

    def config(config)
      raise ConfigError, "Missing shortener section in config/credentials.yml" unless config      

      @@gate = GoShortener.new config[:token]

      puts "Initialized Shortener module"
    end


    def link(uri)
      # Google API token works only with known ips.
      @@gate.shorten uri
    rescue
      uri
    end

  end

end
