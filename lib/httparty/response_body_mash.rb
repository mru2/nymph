module HTTParty

  require 'yajl'
  require 'hashie/mash'


  # Automatically wrap responses in Hashie::Mashes
  module ResponseBodyMash

    def self.included(base)
      base.default_options[:parser] = Parser
    end

    class Parser < HTTParty::Parser
      def parse

        return nil if body.nil? || body.strip.empty? || body == 'null'

        # Assuming JSON
        data = Yajl::Parser.parse(@body)

        case data
        when Hash
          Hashie::Mash.new data
        when Array
          data.map{ |item| Hashie::Mash.new item }
        else
          data
        end

      end
    end

  end

end
