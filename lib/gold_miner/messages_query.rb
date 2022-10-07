module GoldMiner
  class MessagesQuery
    attr_reader :channel, :start_date, :topic

    def initialize
      @channel = nil
      @start_date = nil
      @topic = nil
    end

    def on_channel(channel)
      @channel = channel

      self
    end

    def sent_after(start_date)
      @start_date = start_date

      self
    end

    def sent_since_last_friday
      sent_after(last_friday)

      self
    end

    def til_messages
      @topic = "TIL"

      self
    end

    def tip_messages
      @topic = "tip"

      self
    end

    def to_s
      [topic, channel && "in:#{channel}", start_date && "after:#{start_date}"].compact.join(" ")
    end

    private

    def last_friday
      date = Date.today
      one_day_ago = (date - 1)
      one_week_ago = date - 7

      one_day_ago.downto(one_week_ago).find { |date| date.friday? }.strftime("%Y-%m-%d")
    end
  end
end
