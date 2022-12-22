module GoldMiner
  class MessagesQuery
    attr_reader :channel, :start_date, :topic, :reaction

    def initialize
      @channel = nil
      @start_date = nil
      @topic = nil
      @reaction = nil
    end

    def on_channel(channel)
      @channel = channel

      self
    end

    def sent_after(start_date)
      @start_date = start_date

      self
    end

    def sent_after_last_friday
      sent_after(Helpers::Time.last_friday)

      self
    end

    def with_topic(topic)
      @topic = topic

      self
    end

    def with_reaction(reaction)
      @reaction = reaction

      self
    end

    def to_s
      [
        topic,
        channel && "in:#{channel}",
        start_date && "after:#{start_date}",
        reaction && "has::#{reaction}:"
      ].compact.join(" ")
    end
  end
end
