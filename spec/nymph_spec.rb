require 'spec_helper'

describe Nymph::Client do

  # The tested service
  class SampleService < Sinatra::Base

    register Nymph::Service

    get '/foo' do
      respond_with 'bar'
    end

    get '/splatted/url/handling' do
      respond_with 'ok'
    end

    get '/splatted/with/params' do
      respond_with params[:id].to_i
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

    post '/add_new' do
      respond_with id: 1
    end

    get '/with_url/:id' do
      respond_with id: params[:id].to_i
    end

    get '/with_query_string' do
      respond_with id: params[:id].to_i
    end

    post '/with_body' do
      respond_with id: params[:id].to_i
    end

    put '/invalid' do
      respond_with_error 422, 'invalid parameters'
    end

    get '/server_error' do
      raise "foo" # 500
    end

  end


  shared_examples 'any client' do

    it 'should send a request and receive a response' do
      response = client.get('/foo')

      response.status.should == 200
      response.data.should == 'bar'
    end

    it 'should handle 404s as having no data' do
      response = client.get '/not_found'

      response.success?.should == false
      response.status.should == 404
      response.data.should be_nil
    end

    it 'should have banged getters' do
      client.get!('/foo').should == 'bar'
    end

    it 'should have calls via splatted urls' do
      client.get!(:splatted, :url, :handling).should == 'ok'
      client.get!(:splatted, :with, :params, id: 12).should == 12
    end

    it 'should handle objects in responses, with direct and indifferent access' do
      data = client.get! :object
      data.keys.should == ['foo', 'bar']
      data.foo.should == 'foo'
      data['foo'].should == 'foo'
      data[:foo].should == 'foo'
    end

    it 'should handle collections in responses, with direct access' do
      data = client.get! :collection
      data.should == [{'foo' => 'foo'}, {'bar' => 'bar'}]
      data.first.foo.should == 'foo'
    end

    it 'should handle other verbs' do
      response = client.post '/add_new'
      response.success?.should == true
      response.data.should == {'id' => 1}
    end

    it 'should handle params passing in urls' do
      data = client.get! :with_url, 32
      data.id.should == 32
    end

    it 'should handle params passing in the query string' do
      data = client.get! :with_query_string, id: 43
      data.id.should == 43
    end

    it 'should handle params passing in the body' do
      data = client.post! :with_body, id: 54
      data.id.should == 54
    end

    it 'should catch and format errors' do
      response = client.put '/invalid'
      response.success?.should == false
      response.status.should == 422
      response.error.should == 'invalid parameters'
    end

    it 'should raise an error on banged failed gets' do
      data = client.get! '/not_found'
      data.should be_nil

      expect { client.put! '/invalid' }.to raise_error(Nymph::Client::Error)
    end

    it 'should catch server errors and format them' do
      response = client.get :server_error
      response.status.should == 500
      response.error.should == 'An unexpected error happened'
    end
  end


  context 'local service' do
    it_behaves_like 'any client' do
      let (:client) { Nymph::Client.new(local: SampleService) }
    end
  end


  context 'remote service' do

    before(:all) do
      @server = Thread.new{ Rack::Handler::WEBrick.run SampleService, Port: 19292 }
      puts "Waiting for server to boot"
      sleep(1)
    end

    after(:all) do
      puts "Killing server"
      sleep(1)
      Thread.kill(@server)      
    end

    it_behaves_like 'any client' do
      let (:client) { Nymph::Client.new(host: "http://localhost:19292/") }
    end

  end

end
