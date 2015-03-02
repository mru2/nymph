module Nymph

  module Client

    # Error (handle status codes)
    # TODO : handle subclasses (timeouts, 500s, unauthorized, ...)
    class Error < StandardError
      def initialize(status, body)
        super("Error #{status} : #{body}")
      end
    end

  end

end