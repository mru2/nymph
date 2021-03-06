module Nymph

  require 'httparty'
  require 'nymph/httparty_extensions'

  module Client

    def self.included(base)
      base.include HTTParty
      base.include HTTParty::ResponseBodyMash
      base.include HTTParty::RackProxy
      base.include HTTParty::Prefix
      base.include HTTParty::SplattedPaths
      base.include HTTParty::BangedCalls

      base.format :json
      base.prefix '/v1'
    end


    # ========================
    # Standard client creation
    # ========================
    def self.local(service_class)
      Class.new do
        include Nymph::Client
        rack service_class
      end
    end

    def self.remote(host)
      Class.new do
        include Nymph::Client
        base_uri host
      end
    end

  end

end
