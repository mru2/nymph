require 'grape'
require 'grape-entity'
require 'grape-swagger'

module Nymph

  # Preconfigured grape with extensions
  module Service

    def self.extended(base)      

      base.format :json

      # CORS
      base.before do
        header['Access-Control-Allow-Origin'] = '*'
        header['Access-Control-Request-Method'] = '*'
      end

    end

    # Generates the docs
    def specs
      add_swagger_documentation(
        mount_path: '/specs', 
        hide_documentation_path: true, 
        format: :json
      )
    end 

  end

end
