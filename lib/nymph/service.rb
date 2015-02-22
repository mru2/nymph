module Nymph

  require 'sinatra'
  require 'yajl'

  # Sinatra mixin with preconfigurations for JSON HTTP services
  module Service

    def self.registered(app)
      
      app.disable :show_exceptions
      app.disable :raise_errors
      app.disable :protection

      # Respond with json
      app.before do
        content_type :json
      end

      # Format error messages
      app.error do
        respond_with_error 500, 'An unexpected error happened'
      end

      # Route not found => empty 404
      app.not_found do
        respond_with_none
      end

      # https://github.com/kyledrake/sinatra-jsonapi/blob/master/lib/sinatra/jsonapi.rb
      app.error Sinatra::NotFound do
        not_found
      end


      app.helpers do

        def respond_with_error(code, message)
          status code
          data = { error: { message: message } }
          halt serialize_data(data)
        end

        def respond_with_none
          respond_with_error 404, 'content not found'
        end

        def respond_with data
          if data.nil?
            respond_with_none
          else
            halt serialize_data(data)
          end
        end

        def serialize_data(data)
          Yajl::Encoder.encode data
        end

        # Handle indifferent access
        def params
          # Query string and URL params
          params = super

          # Merge json body if present
          if body_params = Yajl::Parser.parse(request.body)
            params.merge! body_params
          end            

          indifferent_params(params)
        end

      end

    end

  end

end