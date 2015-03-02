module SampleService

  require_relative './view.rb'
  require_relative './model.rb'

  require 'nymph/service'

  class Api < Grape::API

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

end