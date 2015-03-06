module HTTParty

  # Allow to reconstruct paths from a list of arguments
  # get :comments, 1, :author 
  # => get '/comments/1/author'
  module SplattedPaths

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Override HTTP calls to handle splatted paths
      VERBS.each do |verb|

        define_method verb, ->(*args, &block) do
          options = args.last.is_a?(::Hash) ? args.pop : {}
          path = join_path(args)
          options = handle_params(verb, options)
          super(path, options, &block)
        end

      end


      private

      def join_path(fragments)
        fragments.inject('') do |path, fragment|
          fragment = fragment.to_s
          path += '/' unless fragment.start_with? '/'
          path += fragment
        end
      end

      # Set params in body or query if not specified
      def handle_params(verb, options)
        return if options.has_key?(:query) || options.has_key?(:body)

        if verb == :get
          {query: options}
        else
          {body: options}
        end

      end

    end

  end

end