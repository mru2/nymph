module Nymph

  require 'httparty'

  class Client

    # Response
    class Response < Struct.new(:status, :body)

      # Helpers for common http codes
      def success?
        status == 200
      end

      def not_found?
        status == 404
      end

      # Lazy JSON parsing
      def data
        @data ||= (status == 404) ? nil : JSON.parse(body)
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
        raise ArgumentError('The provided local service isn\'t a valid Nymph service') unless service_class <= Nymph::Service 
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
      Response.new(status, body)
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

  end

end