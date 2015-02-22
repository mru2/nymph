module SampleApp

  require 'nymph/service'

  class Logic < Sinatra::Base

    register Nymph::Service

    get '/foo' do
      respond_with 'bar'
    end

    get '/not_found' do
      respond_with_none
    end

    get '/object' do
      respond_with foo: 'foo', bar: 'bar'
    end

    get '/collection' do
      respond_with [ { foo: 'foo' }, { bar: 'bar' } ]
    end

  end

end