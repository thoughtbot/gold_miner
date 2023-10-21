class GoldMiner
  class BlogPost
    class SimpleWriter
      module TopicExtractor
        LANGUAGE_MATCHERS = {
          "Ruby" => ["ruby", "ruby on rails"],
          "Elixir" => ["elixir"],
          "JavaScript" => ["javascript", "js", "node", "nodejs", "yarn", "npm"],
          "TypeScript" => ["typescript", "ts"],
          "SQL" => ["sql"],
          "CSS" => ["css"]
        }.freeze
        TOOL_MATCHERS = {
          "Ruby on Rails" => ["ruby on rails"],
          "React" => ["react", "reactjs"],
          "React Native" => ["react native"],
          "Tailwind" => ["tailwind css", "tailwindcss", "tailwind"]
        }
        TECHNIQUE_MATCHERS = {
          "Refactoring" => ["refactor", "refactoring"],
          "Testing" => ["test", "tests", "testing"]
        }.freeze
        PARDIGM_MATCHERS = {
          "Functional Programming" => ["functional programming"],
          "OOP" => ["object oriented programming", "oop"]
        }.freeze
        OTHER_MATCHERS = {
          "TIL" => ["til", "today i learned", "today i learnt"],
          "Tip" => ["tip", "tips"]
        }
        TOPIC_MATCHERS = {
          **LANGUAGE_MATCHERS,
          **TECHNIQUE_MATCHERS,
          **TOOL_MATCHERS,
          **PARDIGM_MATCHERS,
          **OTHER_MATCHERS
        }.freeze

        def self.call(message_text)
          words = message_text.downcase.split(/\W/)
          sanitized_text = words.join(" ")
          topics = Set[]

          TOPIC_MATCHERS.each do |topic_label, topic_matchers|
            topic_matchers.each do |topic_matcher|
              topics << topic_label if sanitized_text.match?(/\b#{topic_matcher}\b/)
            end
          end

          topics.to_a
        end
      end
    end
  end
end
