require 'spec_helper'

describe Nymph::Client do

  require_relative 'sample_app/logic'

  shared_examples 'any client' do

    it 'should send a request and receive a response' do
      response = client.get('/foo')

      response.status.should == 200
      response.data.should == 'bar'
    end

    it 'should handle 404s as having no data' do
      response = client.get '/not_found'

      response.status.should == 404
      response.data.should be_nil
    end

    it 'should handle objects in responses, with direct access' do
      response = client.get('/object')
      response.data.keys.should == ['foo', 'bar']
      response.data.foo.should == 'foo'
    end

    it 'should handle collections in responses, with direct access' do
      response = client.get('/collection')
      response.data.should == [{'foo' => 'foo'}, {'bar' => 'bar'}]
      response.data.first.foo.should == 'foo'
    end
  end

  context 'local service' do
    it_behaves_like 'any client' do
      let (:client) { Nymph::Client.new(local: SampleApp::Logic) }
    end
  end


  context 'remote service' do

    require_relative 'sample_app/logic'

    before(:all) do
      @server = Thread.new{ Rack::Handler::WEBrick.run SampleApp::Logic, Port: 19292 }
      puts "Waiting for server to boot"
      sleep(1)
    end

    after(:all) do
      puts "Killing server"
      Thread.kill(@server)      
    end

    it_behaves_like 'any client' do
      let (:client) { Nymph::Client.new(host: "http://localhost:19292/") }
    end

  end

end
