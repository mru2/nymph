module Nymph

  require 'httparty'
  require 'hashie/mash'

  class Client

    # Response
    class Response < Struct.new(:status, :data)

      # Helpers for common http codes
      def success?
        status == 200
      end

      def not_found?
        status == 404
      end

    end

    # Error (handle status codes)
    # TODO : handle subclasses (timeouts, 500s, unauthorized, ...)
    class Error < StandardError
      def initialize(status, body)
        @status = status

        # TODO : handle structured JSON errors
        super(body)
      end
    end


    attr_reader :type

    # @params service : The Nymph service to serve, which can be one of the following:
    # local: <ClassName> the service class (inheriting from Nymph::Service)
    # host: <String> a remote nymph service's hostname with port
    def initialize(service)
      if host = service[:host]
        @type = :remote
        @host = host
      elsif service_class = service[:local]
        raise ArgumentError, 'The provided local service isn\'t a valid Nymph service' unless valid_service?(service_class) 
        @type = :local
        @instance = service_class.new
      end
    end

    
    # Methods for each HTTP verb
    [:get, :post, :put, :delete, :path].each do |verb|
      define_method verb do |path, params = {}|
        request(verb, path, params)
      end

      define_method :"#{verb}!" do |path, params = {}|
        request!(verb, path, params)
      end
    end


    # Verb-less methods
    def request(verb, path, params)
      status, body = fetch(verb, path, params)
      body = nil if status == 404
      Response.new status, parse_response(body)
    end

    def request!(verb, path, params)
      response = request(verb, path, params)
      if response.success? || response.not_found?
        response.body
      else
        raise Error.new(response.status, response.body)
      end
    end


    private


    def fetch(verb, path, params)
      case type
      when :remote
        response = HTTParty.send(verb, "#{@host}#{path}", params)
        [response.code, response.body]
      when :local
        env = Rack::MockRequest.env_for(path, params: params)
        status, headers, body = @instance.call(env)
        [status, body.join]
      end
    end

    def valid_service?(service_class)
      service_class <= Sinatra::Base && service_class.extensions.include?(Nymph::Service)
    end

    def parse_response(body)
      return nil if body.nil? || body.empty?

      data = Yajl::Parser.parse(body)

      case data
      when Hash
        Hashie::Mash.new data
      when Array
        data.map{ |item| Hashie::Mash.new item }
      else
        data
      end
    end

  end

end