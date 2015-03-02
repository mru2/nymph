module Nymph

  require 'httparty'

  require 'nymph/client/request'
  require 'nymph/client/response'
  require 'nymph/client/error'


  module Client


    def self.included(base)
      base.extend ClassMethods
    end


    # =============
    # Configuration
    # =============
    module ClassMethods
      def local_service(service_class)
        raise ArgumentError, 'The provided local service isn\'t a valid Nymph service' unless service_class <= Grape::API
        @type = :local
        @service_instance = service_class.new
      end

      def remote_service(host)
        @type = :remote
        @host = host
      end

      def get_service
        if @type == :local
          [:local, @service_instance]
        else
          [:remote, @host]
        end
      end
    end


    # ========================
    # Standard client creation
    # ========================
    def self.local(service_class)
      client_class = Class.new do
        include Nymph::Client
        local_service service_class
      end

      client_class.new
    end

    def self.remote(host)
      client_class = Class.new do
        include Nymph::Client
        remote_service host
      end

      client_class.new
    end


    # ==========================
    # Methods for each HTTP verb
    # ==========================
    [:get, :post, :put, :delete, :path].each do |verb|
      define_method verb do |*args|
        request(verb, *args)
      end

      define_method :"#{verb}!" do |*args|
        request!(verb, *args)
      end
    end


    # ===============
    # Actual requests
    # ===============
    def request(verb, *args)
      request = Request.build(verb, args)

      type, service_or_host = self.class.get_service

      status, body = case type
      when :remote
        response = HTTParty.send(verb, request.httparty_url(service_or_host), request.httparty_payload)
        [response.code, response.body]
      when :local
        status, headers, body = service_or_host.call(request.rack_env)
        [status, body.body.join] # Body is a Rack::BodyProxy
      end

      Response.build status, body
    end

    def request!(verb, *args)
      response = request(verb, *args)
      if response.success?
        response.data
      else
        if response.status == 404 # Don't raise on 404s, just return nil
          nil
        else
          raise Error.new(response.status, response.error)
        end
      end
    end

  end

end