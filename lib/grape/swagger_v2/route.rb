module Grape::SwaggerV2

  class Route

    attr_reader :route, :app

    def initialize(route, app)
      @route = route
      @app = app
    end

    def path
      # adapt format to swagger format
      parsed_path = route.route_path.gsub('(.:format)', '')
      # This is attempting to emulate the behavior of
      # Rack::Mount::Strexp. We cannot use Strexp directly because
      # all it does is generate regular expressions for parsing URLs.
      # TODO: Implement a Racc tokenizer to properly generate the
      # parsed path.
      parsed_path = parsed_path.gsub(/:([a-zA-Z_]\w*)/, '{\1}')
      # remove the version
      parsed_path.gsub('{version}', app.version)
    end

    def include_in_doc?
      route.route_version.present?
    end

    def verb
      route.route_method.downcase
    end

    def serialize
      {
        summary: route.route_description,
        parameters: route.route_params.map{|name, attrs| serialize_parameter(name, attrs)},
        responses: {
          200 => {
            description: 'successful operation',
            schema: DataType.new(route.route_entity).schema
          }
        }
      }
    end

    def serialize_parameter(name, attrs)
      binding.pry if attrs.empty?

      param_format = case
      when route.route_path.include?(":#{name}")
        'path'
      when %w(POST PUT PATCH).include?(route.route_method)
        'body'
      else
        'query'
      end

      parameter = {
        name:          name,
        in:            param_format,
        description:   attrs[:desc],
        required:      attrs[:required]
      }

      parameter.merge! DataType.new(attrs[:type]).schema

      parameter.merge!(default: attrs[:default]) if attrs[:default] # Meh, needed?
      parameter.merge!(enum: attrs[:values]) if attrs[:values]

      parameter
    end

  end

end
