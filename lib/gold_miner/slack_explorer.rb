require "async"

module GoldMiner
  class SlackExplorer
    def initialize(slack_client, author_config)
      @slack = slack_client
      @author_config = author_config
    end

    def explore(channel, start_on:)
      interesting_messages = interesting_messages_query(channel, start_on)

      Sync do
        til_messages_task = Async { search_messages(interesting_messages.with_topic("TIL")) }
        tip_messages_task = Async { search_messages(interesting_messages.with_topic("tip")) }
        hand_picked_messages_task = Async { search_messages(interesting_messages.with_reaction("rupee-gold")) }

        merge_messages(til_messages_task, tip_messages_task, hand_picked_messages_task)
      end
    end

    private

    def interesting_messages_query(channel, start_on)
      Slack::MessagesQuery
        .new
        .on_channel(channel)
        .sent_after(Date.parse(start_on.to_s))
    end

    def merge_messages(*search_tasks)
      search_tasks
        .flat_map { |task| task.wait.messages.matches }
        .uniq { |message| message[:permalink] }
        .map { |message|
          Slack::Message.new(
            text: message.text,
            author: author_of(message),
            permalink: message.permalink
          )
        }
    end

    def author_of(message)
      Slack::User.new(
        name: message.author_real_name,
        link: link_for(message.username),
        id: message.user,
        username: message.username
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
