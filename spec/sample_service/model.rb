module SampleService

  # Mock model, not persisted
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

end