
This project is still highly a work in progress. The Readme in its state is more of a rough spec / todolist. Until 0.1, features may not be implemented yet


# Nymph

[![Build Status](https://travis-ci.org/mru2/nymph.svg?branch=master)](https://travis-ci.org/mru2/nymph) [![Code Climate](https://codeclimate.com/github/mru2/nymph/badges/gpa.svg)](https://codeclimate.com/github/mru2/nymph)


Nymph is a set of libraries which aims to facilitate the extraction of logic into services for Ruby apps.

It offers 2 abstractions : 
 - a `service` which is a Sinatra app preconfigured with sane defaults for serving data over JSON
 - a `client` allowing to call any service seamlessly, whether it is hosted or just code


## Sample

Extract some of your logic into a service (keeping it in the same codebase)

```ruby
require 'nymph/service'

class CommentsService < Sinatra::Base

  register Nymph::Service

  # Add a comment
  post '/comment' do
    comment = Comment.new(params)
    if comment.save
      respond_with comment
    else
      respond_with_error 422, comment.errors
    end
  end

  # Fetch a posts comments
  get '/post/:post_id' do
    respond_with Comment.where(post_id: params[:post_id]).all
  end

end
```

Use a client to transparently call your service

```ruby
client = Nymph::Client.new(local: CommentsService)

response = client.post '/comment', {
  post_id: 42,
  author_id: 12,
  text: 'It was a long and stormy night ...'
}

response.success?
# => true

response.status
# => 200

comment = response.data
comment.keys
# => ['id', 'post_id', 'author_id', 'text', 'created_at']

comment.id
# => 3
```

Have convenience methods for calling the service

```ruby
comments = client.get! :post, 42 # equivalent to '/post/42'

comments.first.text
# => 'It was a long and stormy night'
```

When you are ready, deploy your service separately, and change only one line in your app : 

```ruby
client = Nymph::Client.new(host: 'http://my-comments.herokuapp.com')
```

