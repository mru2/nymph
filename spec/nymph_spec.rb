require 'spec_helper'

describe Nymph::Client do

  # The tested service
  class CommentEntity < Grape::Entity
    expose :id, documentation: { type: 'Integer', desc: 'Comment ID' }
    expose :post_id, documentation: { type: 'Integer', desc: 'Comment\'s Post ID' }
    expose :text, documentation: { type: 'String', desc: 'Comment\'s body' }
  end

  class Comment
    attr_reader :id, :post_id, :text

    def initialize(id, post_id, text)
      @id = id.to_i
      @post_id = post_id.to_i
      @text = text
    end

    def entity
      CommentEntity.new(self)
    end
  end

  class SampleService < Grape::API

    extend Nymph::Service

    desc "Returns a comment's details" do
     success CommentEntity
    end
    params do
      requires :id, type: Integer, desc: "The post's id"
    end
    get 'comment/:id' do
      if params[:id] == 404
        error! 'Comment not found', 404
      end

      Comment.new(params[:id], 41, 'Lorem Ipsum')
    end

    desc "Return a post's comments" do
     success [CommentEntity]
    end
    params do
      requires :post_id, type: Integer, desc: "The post's id"
    end      
    get 'comments' do
      (1..3).map do |id|
        Comment.new(id, params[:post_id], 'Hello World')
      end
    end


    desc "Post a new comment"
    params do
      requires :post_id, type: Integer, desc: "The post's id"
      requires :text, type: String, desc: "The comment's body" 
    end
    post 'comment' do
      comment = Comment.new(1, params[:post_id], params[:text])
      comment
    end

    specs

  end


  shared_examples 'any client' do

    context 'service communications' do

      it 'should fetch the comments and mash them' do

        response = client.get :comment, 12
        response.status.should == 200
        response.success?.should == true

        # Direct access
        comment = response.data
        comment.id.should == 12
        comment.text.should == 'Lorem Ipsum'

        # Hash access
        comment[:post_id].should == 41

      end


      it 'should handle 404s' do

        res = client.get :comment, 404
        res.status.should == 404
        res.success?.should == false
        res.data.should  == nil

      end


      it 'should allow banged getters' do

        comment = client.get! :comment, 3
        comment.id.should == 3
        comment.text.should == 'Lorem Ipsum'

      end


      it 'should handle parameters passing' do
        comments = client.get! :comments, post_id: 12

        comments.count.should == 3
        comments.first.post_id.should == 12
        comments.first.text.should == 'Hello World'

        new_comment = client.post! :comment, post_id: 31, text: 'foobar'
        new_comment.should == {
          'id' => 1,
          'post_id' => 31,
          'text' => 'foobar'
        }
      end


      it 'should handle malformed requests' do

        res = client.get :comments,  post: 31

        res.success?.should == false
        res.status.should == 400
        res.error.should == 'post_id is missing'

        expect{ client.get! :comments, post: 31 }.to raise_error Nymph::Client::Error

      end

    end


  end


  context 'local service' do

    context 'standard client' do
      it_behaves_like 'any client' do
        let (:client) { Nymph::Client.local(SampleService) }
      end
    end

    context 'custom client' do
      class CustomLocalClient
        include Nymph::Client
        local_service SampleService
      end

      it_behaves_like 'any client' do
        let (:client) { CustomLocalClient.new }
      end
    end

  end


  context 'remote service' do

    before(:all) do
      @server = Thread.new{ Rack::Handler::WEBrick.run SampleService, Port: 19292 }
      puts "Waiting for server to boot"
      sleep(3)
    end

    after(:all) do
      puts "Killing server"
      sleep(1)
      Thread.kill(@server)
    end

    context 'standard client' do

      it_behaves_like 'any client' do
        let (:client) { Nymph::Client.remote('http://localhost:19292') }
      end

    end

    context 'custom client' do

      class CustomRemoteClient
        include Nymph::Client
        remote_service 'http://localhost:19292'
      end

      it_behaves_like 'any client' do
        let (:client) { CustomRemoteClient.new }
      end

    end
  end

end
