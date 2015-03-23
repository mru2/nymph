$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'

require 'nymph/client'
require 'nymph/service'

require './spec/sample_service/api.rb'
Rack::Handler::WEBrick.run SampleService::Api, Port: (ENV['PORT'] || 9292)
