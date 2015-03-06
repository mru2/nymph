module HTTParty

  # Allow an HTTParty client to request rack apps directly
  module RackProxy

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def rack(rack_app_class)
        app = rack_app_class.new
        raise ArgumentError, "No Rack App provided" unless app.respond_to? :call
        default_options[:rack_app] = rack_app_class.new
      end
    end

  end


  class Request

    alias_method :perform_without_rack, :perform

    # Mock an HTTP call to the rack app
    def perform(&block)
      return perform_without_rack(&block) unless options.has_key? :rack_app

      # Actual rack call
      code, headers, body = options[:rack_app].call rack_env
      body = body.body if body.is_a? Rack::BodyProxy

      MockResponse.new code, headers, body, lambda { parse_response(body.join) }
    end

    private

    def rack_env
      headers = options[:headers] || {}
      headers[:method] = http_method.to_s.split('::').last.downcase
      headers[:params] = options[:query]

      # Should use the native HTTParty formatting here instead
      if options[:body]
        headers['CONTENT_TYPE'] = 'application/json'
        headers[:input] = Yajl::Encoder.encode(options[:body])
      end

      Rack::MockRequest.env_for path.to_s, headers
    end

  end


  class MockResponse

    def initialize(code, headers, body, parsed_block)
      @rack_response = Rack::Response.new(body, code, headers)
      @parsed_block = parsed_block
    end

    def code
      @rack_response.status
    end

    def parsed_response
      @parsed_response ||= @parsed_block.call
    end

    def success?
      @rack_response.successful?
    end

    def error
      return nil if success?
      parsed_response.error
    end

  end
end
