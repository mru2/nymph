module HTTParty

  # Allow an HTTParty client to prefix every path (ie, for API versioning)
  # Used by the configuration flag `prefix '/v1'`
  module Prefix

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def prefix(prefix)
        default_options[:prefix] = prefix
      end

      # Override HTTP calls to include prefixing
      VERBS.each do |verb|
        define_method verb do |path, options, &block|

          if (prefix = default_options[:prefix]) &&
             !path.start_with?(prefix)

             path = prefix + path
          end

          super(path, options, &block)
        end
      end
    end

  end

end
