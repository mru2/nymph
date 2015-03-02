module SampleService

  # View logic for the comments
  class CommentEntity < Grape::Entity
    expose :id, documentation: { type: 'Integer', desc: 'Comment ID' }
    expose :post_id, documentation: { type: 'Integer', desc: 'Comment\'s Post ID' }
    expose :text, documentation: { type: 'String', desc: 'Comment\'s body' }
  end

end