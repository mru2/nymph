module Nymph

  module Client

    # Wrapper around a service request
    # Convertible into an HTTParty payload or a Rack::MockRequest
    class Request

      def self.build(verb, args)
        # Fetch params and path
        params = args.last.is_a?(::Hash) ? args.pop : {}

        # Handle when a path is directly given
        if args.count == 1 && args.first.to_s.start_with?('/')
          path = args.first.to_s
        else
          path = "/#{args.join('/')}"
        end

        new(verb, path, params)
      end

      def initialize(verb, path, params)
        @verb = verb
        @path = path
        @params = params || {}
      end

      def httparty_url(host)
        "#{host}#{@path}"
      end

      def httparty_payload
        payload = get? ? { query: @params } : { body: json_body }
        payload[:headers] = headers
        payload
      end

      def rack_env
        options = {
          method: @verb
        }

        if get?
          options[:params] = @params
        else
          options['CONTENT_TYPE'] = 'application/json'
          options[:input] = json_body
        end

        Rack::MockRequest.env_for @path, options
      end

      
      private

      def get?
        @verb == :get
      end

      def json_body
        return '' if @params.empty?
        Yajl::Encoder.encode(@params)
      end

      def headers
        {
          'Content-Type' => 'application/json'
        }
      end

    end

  end

end

