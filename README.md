# Nymph

[![Build Status](https://travis-ci.org/mru2/nymph.svg?branch=master)](https://travis-ci.org/mru2/nymph) [![Code Climate](https://codeclimate.com/github/mru2/nymph/badges/gpa.svg)](https://codeclimate.com/github/mru2/nymph)


## About

Nymph is a set of libraries which aims to facilitate the extraction of logic into services for Ruby apps.

### Goals

You should be able to progressively extract application logic into a local service, without having to wonder about its hosting or deployment.

You should be able to remotely host your service in the future, without changing more than one line in your application's code.

You should be able to quickly iterate on your service's API, and have your client's mocks enforce the compatibility.


### Stack

The (opinionated) technology stack behind it is :
 - [grape](https://github.com/intridea/grape) along with [grape-entity](https://github.com/intridea/grape-entity) for the service side
 - [httparty](https://github.com/jnunemaker/httparty), [yajl](https://github.com/brianmario/yajl-ruby), and [hashie](https://github.com/intridea/hashie) for the client side
 - [swagger](http://swagger.io/) for automatically generating the service documentation, and the client mocks


### Status

This gem is currently a work in progress. This README reflects the goals of the v1, and not the actual status.


## Extracting a blog's comments into a service

Assuming we have a Blog application, we are going to extract into a service the ability to handle comments (fetching a post's comments, and posting a new comment)

### 1. Define your resource representations

Assuming we already have a `Comment` model (activerecord or otherwise), we will be using grape entities to enforce resource representations. Think of it as the view layer of your service.

```ruby
# /app/services/comments_service/views/comment_entity.rb

class Comments::CommentEntity < Grape::Entity
  expose :id,      documentation: { type: 'Integer', desc: 'Unique identifier' }
  expose :post_id, documentation: { type: 'Integer', desc: 'The commented post' }
  expose :author,  documentation: { type: 'String',  desc: 'The authors username' }
  expose :text,    documentation: { type: 'String',  desc: 'The HTML comment body' }
end
```

You should also include the following in your model, in order to automate the JSON generation :
```ruby
# /app/services/comments_services/models/comment.rb
class Comments::Comment < ActiveRecord::Base
  # [ ... ]
  def entity
    CommentEntity.new(self)
  end  
end 
```


### 2. Define the public API

Your endpoints must be documented

```ruby
# /app/services/comments/api.rb
require 'nymph/service'
class Comments::API < Grape::API
  
  extend Nymph::Service

  # GET /comments?post_id=<the posts id>
  desc 'Returns all the comments for a post, in reverse chronological order' do
    success [CommentEntity]
  end
  params do 
    requires :post_id, type: Integer, desc: "The post's id"
  end
  get 'comments' do
    Comment.where(post_id: params[:post_id]).order('created_at DESC').all
  end


  # POST /comment
  desc 'Post a new comment for a given post' do
    success [CommentEntity]
  end
  params do
    requires :post_id, type: Integer, desc: "The post's id"
    requires :author,  type: String, desc: "The author's username"
    requires :text,    type: String, desc: "The comment's body"
  end
  post 'comment' do
    comment = Comment.new(params)

    if comment.save
      comment
    else
      error! 'Invalid parameters', 422
    end
  end

end
```


### 3. Call the service from your application

You may instanciate a client in a single line

```ruby
require 'nymph/client'
client = Nymph::Client.local Comments::API
```


The response is automatically wrapped in instances of `Hashie::Mash`

```ruby
comments = client.get! :comments, post_id: 12

comments.map(&:author)
# => ['darrent', 'trevor', 'timmy']
```


You may call banged methods for direct access to the response data (an error will be raised on a service error), or normal calls if you wish to check the response status :

```ruby
response = comments.get :comments, post_id: 42

response.status
# => 200

response.success?
# => true

response.error
# => nil (would be the error message)
```

You may also create a custom client

```ruby
class CommentPoster

  # Include the support for service calls
  include Nymph::Client
  local_service Comments::API
 
  def initialize(user)
    @user = user
  end

  # Returns the comment id
  def add_comment(post, text)
    comment = post! :comment, post_id: post.id, author: @user.username, text: text
    comment.id
  end

end

```


### 4. Mock the service calls in your unit tests

TODO


### 5. Consult the service documentation

TODO


### 6. Host the service remotely

TODO


