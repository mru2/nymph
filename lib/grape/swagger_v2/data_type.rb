module Grape::SwaggerV2

  class DataType

    PRIMITIVES = {
      'Integer' => {
        type: 'integer',
        format: 'int64'
      },
      'Float' => {
        type: 'number',
        format: 'double'
      },
      'String'   => { type: 'string' },
      'Symbol'   => { type: 'string' },
      'Boolean'  => { type: 'boolean' },
      'Virtus::Attribute::Boolean' => { type: 'boolean' },
      'Date'     => { type: 'date' },
      'DateTime' => { type: 'datetime' }
    }

    attr_reader :source


    # Also internally store any encountered entities, in order to serve their definitions
    # There should be a better way to do this than a class variable but this seems to work
    def self.definitions
      @definitions ||= {}
    end

    def self.register_entity(entity_class)
      unless definitions.has_key? entity_class.name
        # Create the schema here to handle recursive definitions
        properties = entity_class.exposures.reduce({}) do |acc, (name, exposure)|
          acc[name] = DataType.new(exposure[:documentation][:type]).schema.merge(
            description: exposure[:documentation][:desc]
          )
          acc
        end

        definitions[entity_class.name] = {properties: properties}
      end

      "#/definitions/#{entity_class.name}"
    end


    # Source type can be one of
    # - a primitive class stringified
    # - an entity
    # - an array of one of those
    def initialize(source)
      @source = source
    end

    def schema
      if PRIMITIVES.has_key? source
        PRIMITIVES[source]
      elsif source.is_a? Array
        {
          type: 'array',
          items: DataType.new(source[0]).schema
        }
      elsif source < Grape::Entity
        {
          '$ref' => self.class.register_entity(source)
        }
      end
    end

  end

end
