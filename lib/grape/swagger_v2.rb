require 'grape/swagger_v2/documentation'

module Grape

  # Opens a swagger V2 compliant /swagger.json endpoint
  # serving the documentation for the grape API
  module SwaggerV2

    def self.extended(base)

      base.helpers do
        def swagger_doc
          options[:for].swagger_doc
        end
      end

      base.get '/swagger.json' do
        swagger_doc
      end

    end

    def swagger_doc
      @swagger_doc ||= Grape::SwaggerV2::Documentation.new(self).serialize
    end


  end

end
