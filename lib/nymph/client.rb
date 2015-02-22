module Nymph

  require 'httparty'
  require 'hashie/mash'
  require 'nymph/request'

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

      def error
        return nil if success?
        data.error.message
      end

    end

    # Error (handle status codes)
    # TODO : handle subclasses (timeouts, 500s, unauthorized, ...)
    class Error < StandardError
      def initialize(status, body)
        @status = status

        # TODO : better handle structured JSON errors
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
      define_method verb do |*args|
        request(verb, *args)
      end

      define_method :"#{verb}!" do |*args|
        request!(verb, *args)
      end
    end


    # Verb-less methods
    def request(verb, *args)
      path, params = parse_arguments(args)
      request = Request.new(verb, path, params)

      status, body = case type
      when :remote
        response = HTTParty.send(verb, request.httparty_url(@host), request.httparty_payload)
        [response.code, response.body]
      when :local
        status, headers, body = @instance.call(request.rack_env)
        [status, body.join]
      end

      Response.new status, parse_response(status, body)
    end

    def request!(verb, *args)
      response = request(verb, *args)
      if response.success? || response.not_found?
        response.data
      else
        raise Error.new(response.status, response.data)
      end
    end


    private

    def valid_service?(service_class)
      service_class <= Sinatra::Base && service_class.extensions.include?(Nymph::Service)
    end

    def parse_arguments(args)
      # Fetch params and path
      params = args.last.is_a?(::Hash) ? args.pop : {}

      # Handle when a path is directly given
      if args.count == 1 && args.first.to_s.start_with?('/')
        path = args.first.to_s
      else
        path = "/#{args.join('/')}"
      end

      [path, params]
    end      

    def parse_response(status, body)
      return nil if status == 404 || body.nil? || body.empty?

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