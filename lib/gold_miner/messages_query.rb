module GoldMiner
  class MessagesQuery
    attr_reader :channel, :start_date, :topic, :reaction

    def initialize(channel: nil, start_date: nil, topic: nil, reaction: nil)
      @channel = channel
      @start_date = start_date
      @topic = topic
      @reaction = reaction
    end

    def on_channel(new_channel)
      with(channel: new_channel)
    end

    def sent_after(new_start_date)
      with(start_date: new_start_date)
    end

    def with_topic(new_topic)
      with(topic: new_topic)
    end

    def with_reaction(new_reaction)
      with(reaction: new_reaction)
    end

    def with(**new_attributes)
      old_attributes = {channel: channel, start_date: start_date, topic: topic, reaction: reaction}

      self.class.new(**old_attributes.merge(new_attributes))
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
