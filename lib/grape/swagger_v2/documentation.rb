module Grape::SwaggerV2

  require 'grape/swagger_v2/route'
  require 'grape/swagger_v2/data_type'

  class Documentation

    attr_reader :app, :paths, :definitions

    def initialize(app)
      @app = app
      @paths = {}

      # Parse each route (for the path and the associated definitions)
      app.routes.each do |route|
        route = Route.new(route, app)

        next if route.is_swagger_doc?

        register_route! route
      end

      # Now declare all encoutered entities
      @definitions = DataType.definitions
    end


    def serialize
      Hashie::Mash.new(
        swagger: '2.0',
        info: {
          title: app.name,
          description: "This is an auto-generated documentation for the #{app.name} grape API.",
          version: app.version
        },
        consumes: ['application/json'],
        produces: ['application/json'],
        schemes: ['http'],
        paths: paths,
        definitions: definitions
      )
    end


    private

    def register_route!(route)
      paths[route.path] ||= {}
      paths[route.path][route.verb] = route.serialize
    end

  end

end
