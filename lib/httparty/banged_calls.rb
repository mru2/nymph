module HTTParty

  # Allow using banger #get! #post! ... calls, directly 
  # returning the response body, raising an exception on errors
  module BangedCalls

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Handle banged calls
      VERBS.each do |verb|

        define_method :"#{verb}!", ->(*args, &block) do
          response = send(verb, *args, &block)

          if !response.success?
            # Should be made more clear
            raise Error, "ERROR #{response.code} : #{response.parsed_response.error}"
          end

          response.parsed_response
        end

      end

    end

  end

end