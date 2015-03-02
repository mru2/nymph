module Nymph

  module Client

    require 'hashie/mash'
    require 'yajl'

    # Response Wrapper
    class Response < Struct.new(:status, :data)

      def self.build(status, body)
        if status == 404 || body.nil? || body.empty?
          data = nil
        else
          parsed_body = Yajl::Parser.parse(body)

          data = case parsed_body
          when Hash
            Hashie::Mash.new parsed_body
          when Array
            parsed_body.map{ |item| Hashie::Mash.new item }
          else
            parsed_body
          end
        end

        new(status, data)
      end

      # Helpers for common http codes
      def success?
        status / 100 == 2
      end

      def not_found?
        status == 404
      end

      def error
        return nil if success?
        data.error
      end

    end

  end

end