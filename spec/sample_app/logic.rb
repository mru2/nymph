module SampleApp

  require 'nymph/service'

  class Logic < Nymph::Service

    get '/foo' do
      'bar'
    end

  end

end