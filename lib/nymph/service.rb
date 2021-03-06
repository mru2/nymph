require 'grape'
require 'grape-entity'
require 'grape/swagger_v2'

module Nymph

  # Preconfigured grape with extensions
  module Service

    # Ordering matters (version in the end notably ...)
    def self.extended(base)

      base.format :json

      # CORS
      base.before do
        header['Access-Control-Allow-Origin'] = '*'
        header['Access-Control-Request-Method'] = '*'
      end

      base.extend Grape::SwaggerV2

      base.version 'v1'

    end

  end

end
