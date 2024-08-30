# frozen_string_literal: true

require "json"

RSpec.describe GoldMiner::BlogPost::OpenAiWriter do
  it_behaves_like "a blog post writer" do
    let(:writer_instance) do
      described_class.new(
        open_ai_api_token: "token",
        fallback_writer: double("fallback_writer")
      )
    end
  end

  describe "#extract_topics_from" do
    it "returns a list of topics from the message text" do
      token = "valid-token"
      writer = described_class.new(open_ai_api_token: token, fallback_writer: double("fallback_writer"))
      gold_nugget = TestFactories.create_gold_nugget
      open_ai_topics = ["Ruby", "Enumerable"]
      request = stub_open_ai_request(
        token: token,
        prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}",
        response_status: 200,
        response_body: {
          "choices" => [{"message" => {"role" => "assistant", "content" => open_ai_topics.to_json}}]
        }
      )

      topics = writer.extract_topics_from(gold_nugget)

      expect(topics).to eq(open_ai_topics)
      expect(request).to have_been_requested.once
    end

    context "when OpenAI returns a JSON wrapped in backticks" do
      it "removes the backticks and parses the JSON" do
        token = "valid-token"
        gold_nugget = TestFactories.create_gold_nugget
        json = '`["Ruby"]`'
        request = stub_open_ai_request(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}",
          response_status: 200,
          response_body: {
            "choices" => [{"message" => {"role" => "assistant", "content" => json}}]
          }
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: double("fallback_writer"))

        topics = writer.extract_topics_from(gold_nugget)

        expect(topics).to eq(["Ruby"])
        expect(request).to have_been_requested.once
      end
    end

    context "when OpenAI returns an invalid JSON" do
      it "uses the fallback writer" do
        token = "valid-token"
        gold_nugget = TestFactories.create_gold_nugget
        invalid_json = '{"Ruby"}'
        request = stub_open_ai_request(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}",
          response_status: 200,
          response_body: {
            "choices" => [{"message" => {"role" => "assistant", "content" => invalid_json}}]
          }
        )
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        topics = writer.extract_topics_from(gold_nugget)

        expect(topics).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(gold_nugget)
        expect(request).to have_been_requested.once
      end
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        request = stub_open_ai_error(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.extract_topics_from(gold_nugget)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
        expect(request).to have_been_requested.once
      end

      it "uses the fallback writer to extract topics" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        request = stub_open_ai_error(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}",
          response_error: "Some error"
        )
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        topics = writer.extract_topics_from(gold_nugget)

        expect(topics).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(gold_nugget)
        expect(request).to have_been_requested.once
      end
    end

    context "when an SocketError is raised" do
      it "uses the fallback writer" do
        mock_client_instance = instance_double(OpenAI::Client)
        allow(mock_client_instance).to receive(:chat).and_raise(SocketError)
        mock_client_class = class_double(OpenAI::Client, new: mock_client_instance)
        token = "valid-token"
        gold_nugget = TestFactories.create_gold_nugget
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer, open_ai_client: mock_client_class)
        topics = writer.extract_topics_from(gold_nugget)

        expect(topics).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(gold_nugget)
      end
    end
  end

  describe "#give_title_to" do
    it "returns the message permalink" do
      token = "valid-token"
      writer = described_class.new(open_ai_api_token: token, fallback_writer: double("fallback_writer"))
      gold_nugget = TestFactories.create_gold_nugget
      open_ai_title = "\n\n\"The Power of Enumerable#each_with_object\""
      request = stub_open_ai_request(
        token: token,
        prompt: "Give a small title to this text: #{gold_nugget.content}",
        response_status: 200,
        response_body: {
          "choices" => [{"message" => {"role" => "assistant", "content" => open_ai_title}}]
        }
      )

      title = writer.give_title_to(gold_nugget)

      expected_title = open_ai_title.strip.delete('"')
      expect(title).to eq(expected_title)
      expect(request).to have_been_requested.once
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        request = stub_open_ai_error(
          token: token,
          prompt: "Give a small title to this text: #{gold_nugget.content}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.give_title_to(gold_nugget)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
        expect(request).to have_been_requested.once
      end

      it "uses the fallback writer to return a title" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        request = stub_open_ai_error(
          token: token,
          prompt: "Give a small title to this text: #{gold_nugget.content}",
          response_error: "Some error"
        )
        fallback_title = "[TODO]"
        fallback_writer = stub_fallback_writer(give_title_to: fallback_title)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.give_title_to(gold_nugget)

        expect(title).to eq(fallback_title)
        expect(fallback_writer).to have_received(:give_title_to).with(gold_nugget)
        expect(request).to have_been_requested.once
      end
    end
  end

  describe "#summarize" do
    it "returns a summary of the given text" do
      token = "valid-token"
      gold_nugget = TestFactories.create_gold_nugget
      open_ai_summary = "\n\nEnumerable#each_with_object is like #reduce, but easier to understand."
      request = stub_open_ai_request(
        token: token,
        prompt:
          "Summarize the following markdown message without removing the author's blog link.\nKeep code examples and links, if any. Return the summary as markdown.\n\nMessage:\n#{gold_nugget.as_conversation}",
        response_status: 200,
        response_body: {
          "choices" => [{"message" => {"role" => "assistant", "content" => open_ai_summary}}]
        }
      )
      writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)
      summary = writer.summarize(gold_nugget)

      expect(summary).to eq <<~SUMMARY.strip
        #{open_ai_summary.strip}

        Source: #{gold_nugget.source}
      SUMMARY
      expect(request).to have_been_requested.once
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        request = stub_open_ai_error(
          token: token,
          prompt:
            "Summarize the following markdown message without removing the author's blog link.\nKeep code examples and links, if any. Return the summary as markdown.\n\nMessage:\n#{gold_nugget.as_conversation}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.summarize(gold_nugget)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
        expect(request).to have_been_requested.once
      end

      it "uses the fallback writer to return a summary" do
        token = "invalid-token"
        gold_nugget = TestFactories.create_gold_nugget
        request = stub_open_ai_error(
          token: token,
          prompt:
            "Summarize the following markdown message without removing the author's blog link.\nKeep code examples and links, if any. Return the summary as markdown.\n\nMessage:\n#{gold_nugget.as_conversation}",
          response_error: "Some error"
        )
        fallback_summary = "[TODO]"
        fallback_writer = stub_fallback_writer(summarize: fallback_summary)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.summarize(gold_nugget)

        expect(title).to eq(fallback_summary)
        expect(fallback_writer).to have_received(:summarize).with(gold_nugget)
        expect(request).to have_been_requested.once
      end
    end
  end

  private

  def stub_open_ai_error(token:, prompt:, response_error:)
    stub_open_ai_request(
      token: token,
      prompt: prompt,
      response_status: 401,
      response_body: {
        "error" => {
          "message" => response_error,
          "type" => "invalid_request_error",
          "param" => nil,
          "code" => "invalid_api_key"
        }
      }
    )
  end

  def stub_open_ai_request(token:, prompt:, response_body:, response_status:)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        body: %({"model":"gpt-4o-mini","messages":[{"role":"user","content":#{prompt.strip.dump}}],"temperature":0}),
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: response_status, body: response_body.to_json, headers: {"Content-Type" => "application/json"})
  end

  def stub_fallback_writer(give_title_to: "[TODO TITLE]", summarize: "[TODO SUMMARY]", extract_topics_from: ["TODO", "TOPICS"])
    double("fallback writer", give_title_to: give_title_to, summarize: summarize, extract_topics_from: extract_topics_from)
  end
end
