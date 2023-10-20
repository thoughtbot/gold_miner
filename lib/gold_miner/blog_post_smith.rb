module GoldMiner
  class BlogPostSmith
    def initialize(blog_post_class: BlogPost, blog_post_writer: BlogPost::Writer.from_env)
      @blog_post_class = blog_post_class
      @blog_post_writer = blog_post_writer
    end

    def smith(gold_container)
      @blog_post_class.new(
        slack_channel: gold_container.origin,
        gold_nuggets: gold_container.gold_nuggets,
        since: gold_container.packing_date,
        writer: @blog_post_writer
      )
    end
  end
end
