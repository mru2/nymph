require 'spec_helper'

describe Nymph::Client do

  context 'local service' do

    let (:client) { Nymph::Client.new(local: SampleApp::Logic) }

    it 'should send a request and receive a response' do
      client.get!('/foo').should == 'bar'
    end

  end


  context 'remote service' do

    require_relative 'sample_app/logic'

    let(:port){ 19292 }
    let (:client) { Nymph::Client.new(host: "http://localhost:#{port}/") }

    around (:context) do |context|
      server = Thread.new{ Rack::Handler::WEBrick.run SampleApp::Logic, Port: port }
      puts "Waiting for server to boot"
      sleep(1)
      
      context.run

      Thread.kill(server)      
    end

    it 'should send a request and receive a response' do
      client.get!('/foo').should == 'bar'
    end

  end


end
