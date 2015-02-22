module Nymph

  # Wrapper around a service request
  # Convertible into an HTTParty payload or a Rack::MockRequest
  class Request

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
      payload[:options] = {
        headers: { 'Content-Type' => 'application/json' }
      }
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

