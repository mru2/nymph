
## This project is still highly a work in progress. The Readme in its state is more of a rough spec / todolist. Until 0.1, features may not be implemented yet


# Nymph

[![Build Status](https://travis-ci.org/mru2/nymph.svg?branch=master)](https://travis-ci.org/mru2/nymph) [![Code Climate](https://codeclimate.com/github/mru2/nymph/badges/gpa.svg)](https://codeclimate.com/github/mru2/nymph)


Nymph is a set of libraries which aims to facilitate the extraction of logic into services for Ruby apps.

It offers a set of helpers for creating services which can then be either called locally or via HTTP. Included are also helpers for mocking/testing these services, and generating their documentation.



## Doc

### Service

Define your service as you would any sinatra application.

```ruby
require 'nymph/service'

class CommentsService < Nymph::Service
  
  # Draper integration
  respond_with_decorator CommentsDecorator

  get '/' do
    if params[:post_id]
      Comment.for_post(post_id).map(&:serialize)
    else
      Comment.all
    end
  end

  get '/:id' do
    Comment.find(id)
  end

  post '/comment' do
    comment = new Comment(
      title: params[:title],
      body: params[:body]
    )

    if comment.save
      comment
    else
      error 422, comment.errors
    end
  end

end
```

A few points to notice
 - nil values return a 404 by default
 - JSON body and GET params are accessible under the `params` helper


### Client

A client for the server we just defined can be instanciated in two ways : 

```ruby
# Locally
comments = Nymph::Client.new(local: CommentsService)

# Remotely
comments = Nymph::Client.new(host: 'http://127.0.0.1:8383')
```

Once instanciated, you can access your service with the following syntax

```ruby
response = comments.get('/12')
```

The response is a mash with the following interface :
```ruby
response.status
# => 200

response.success?
# => true

comment = response.data
comment.title
# => "Hello World"
```

You can specify the verb and send params with your call :
```ruby
response = comments.post('/comment', title: 'Hello', text: 'World')
```

If you are only interested in the response body, you may use banged methods. 404s will return nil and responses with errors will raise an exception
```ruby
comment = Comment.get! '/42'
comment.title
# => "It worked!"

comments = Comment.get! '/', post_id: 43
comments.count
# => 122
comments.first.body
# => "It was a long and stormy night ..."
```

Arguments are converted into paths automatically.
```ruby
class EventsService < Nymph::Service
  get '/:event_id/applications' do
    # [...]
  end

  get '/total' do
    # [...]
  end
end

response = events_service.get(event_id, :applications)
```

You may create a custom client via importing this functionality in a class of your choosing (for decorating results, or better calls)

```ruby
class CommentsClient
  
  include Nymph::Client::Mixin
  nymph_service local: CommentsServer

  def latest(n)
    comments = get! '/comments', order: 'created_at', reverse_order: true
    comments.first(n)
  end

end
```
