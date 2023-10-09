require "async"

module GoldMiner
  class SlackExplorer
    def initialize(slack_client, author_config)
      @slack = slack_client
      @author_config = author_config
    end

    def explore(channel, start_on:)
      start_on = Date.parse(start_on.to_s)
      interesting_messages = interesting_messages_query(channel, start_on)

      Sync do
        til_messages_task = Async { search_messages(interesting_messages.with_topic("TIL")) }
        tip_messages_task = Async { search_messages(interesting_messages.with_topic("tip")) }
        hand_picked_messages_task = Async { search_messages(interesting_messages.with_reaction("rupee-gold")) }
        nuggets = extract_nuggets(til_messages_task, tip_messages_task, hand_picked_messages_task)

        GoldContainer.new(gold_nuggets: nuggets, origin: channel, packing_date: start_on)
      end
    end

    private

    def interesting_messages_query(channel, start_on)
      Slack::MessagesQuery
        .new
        .on_channel(channel)
        .sent_after(start_on)
    end

    def extract_nuggets(*search_tasks)
      search_tasks
        .flat_map(&:wait)
        .uniq { |message| message[:permalink] }
        .map { |message|
          GoldNugget.new(
            content: message.text,
            author: author_of(message),
            source: message.permalink
          )
        }
    end

    def author_of(message)
      Author.new(
        id: message.user.username,
        name: message.user.name,
        link: link_for(message.user.username)
      )
    end

    def search_messages(query)
      @slack.search_messages(query.to_s)
    end

    def link_for(username)
      @author_config.link_for(username)
    end
  end
end
