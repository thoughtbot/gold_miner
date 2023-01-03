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
      message = {text: "Enumerable#each_with_object is a great method in Ruby!"}
      open_ai_topics = ["Ruby", "Enumerable"]
      stub_open_ai_request(
        token: token,
        prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{message[:text]}",
        response_status: 200,
        response_body: {
          "id" => "cmpl-6QiaeoGrqfvf3dFdxHbzDRAGrUBho",
          "object" => "text_completion",
          "created" => 1671825952,
          "model" => "text-davinci-003",
          "choices" => [
            {
              "text" => open_ai_topics.to_json,
              "index" => 0,
              "logprobs" => nil,
              "finish_reason" => "stop"
            }
          ],
          "usage" => {"prompt_tokens" => 21, "completion_tokens" => 15, "total_tokens" => 36}
        }
      )

      topics = writer.extract_topics_from(message)

      expect(topics).to eq(open_ai_topics)
    end

    context "when OpenAI returns an invalid JSON" do
      it "uses the fallback writer" do
        token = "valid-token"
        message = {text: "Enumerable#each_with_object is a great method in Ruby!"}
        invalid_json = '`["Ruby"]`'
        stub_open_ai_request(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{message[:text]}",
          response_status: 200,
          response_body: {
            "id" => "cmpl-6QiaeoGrqfvf3dFdxHbzDRAGrUBho",
            "object" => "text_completion",
            "created" => 1671825952,
            "model" => "text-davinci-003",
            "choices" => [
              {
                "text" => invalid_json,
                "index" => 0,
                "logprobs" => nil,
                "finish_reason" => "stop"
              }
            ],
            "usage" => {"prompt_tokens" => 21, "completion_tokens" => 15, "total_tokens" => 36}
          }
        )
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.extract_topics_from(message)

        expect(title).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(message)
      end
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method!"}
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        stub_open_ai_error(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{message[:text]}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.extract_topics_from(message)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
      end

      it "uses the fallback writer to return a title" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method!"}
        stub_open_ai_error(
          token: token,
          prompt: "Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{message[:text]}",
          response_error: "Some error"
        )
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.extract_topics_from(message)

        expect(title).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(message)
      end
    end

    context "when an SocketError is raised" do
      it "uses the fallback writer" do
        mock_client_instance = instance_double(OpenAI::Client)
        allow(mock_client_instance).to receive(:completions).and_raise(SocketError)
        mock_client_class = class_double(OpenAI::Client, new: mock_client_instance)
        token = "valid-token"
        message = {text: "Enumerable#each_with_object is a great method in Ruby!"}
        fallback_topics = ["Ruby"]
        fallback_writer = stub_fallback_writer(extract_topics_from: fallback_topics)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer, open_ai_client: mock_client_class)
        title = writer.extract_topics_from(message)

        expect(title).to eq(fallback_topics)
        expect(fallback_writer).to have_received(:extract_topics_from).with(message)
      end
    end
  end

  describe "#give_title_to" do
    it "returns the message permalink" do
      token = "valid-token"
      writer = described_class.new(open_ai_api_token: token, fallback_writer: double("fallback_writer"))
      message = {text: "Enumerable#each_with_object is a great method!"}
      open_ai_title = "\n\n\"The Power of Enumerable#each_with_object\""
      stub_open_ai_request(
        token: token,
        prompt: "Give a small title to this text: #{message[:text]}",
        response_status: 200,
        response_body: {
          "id" => "cmpl-6QiaeoGrqfvf3dFdxHbzDRAGrUBho",
          "object" => "text_completion",
          "created" => 1671825952,
          "model" => "text-davinci-003",
          "choices" => [
            {
              "text" => open_ai_title,
              "index" => 0,
              "logprobs" => nil,
              "finish_reason" => "stop"
            }
          ],
          "usage" => {"prompt_tokens" => 21, "completion_tokens" => 15, "total_tokens" => 36}
        }
      )

      title = writer.give_title_to(message)

      expected_title = open_ai_title.strip.delete('"')
      expect(title).to eq(expected_title)
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method!"}
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        stub_open_ai_error(
          token: token,
          prompt: "Give a small title to this text: #{message[:text]}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.give_title_to(message)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
      end

      it "uses the fallback writer to return a title" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method!"}
        stub_open_ai_error(
          token: token,
          prompt: "Give a small title to this text: #{message[:text]}",
          response_error: "Some error"
        )
        fallback_title = "[TODO]"
        fallback_writer = stub_fallback_writer(give_title_to: fallback_title)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.give_title_to(message)

        expect(title).to eq(fallback_title)
        expect(fallback_writer).to have_received(:give_title_to).with(message)
      end
    end
  end

  describe "#summarize" do
    it "returns a summary of the given text" do
      token = "valid-token"
      message = {
        text: "Enumerable#each_with_object is a great method! It's like #reduce, but easier to understand.",
        permalink: "https://example.com/123"
      }
      open_ai_summary = "\n\nEnumerable#each_with_object is like #reduce, but easier to understand."
      stub_open_ai_request(
        token: token,
        prompt: "Summarize this text: #{message[:text]}",
        response_status: 200,
        response_body: {
          "id" => "cmpl-6QiaeoGrqfvf3dFdxHbzDRAGrUBho",
          "object" => "text_completion",
          "created" => 1671825952,
          "model" => "text-davinci-003",
          "choices" => [
            {
              "text" => open_ai_summary,
              "index" => 0,
              "logprobs" => nil,
              "finish_reason" => "stop"
            }
          ],
          "usage" => {"prompt_tokens" => 21, "completion_tokens" => 15, "total_tokens" => 36}
        }
      )
      writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)
      summary = writer.summarize(message)

      expect(summary).to eq <<~SUMMARY.strip
        #{open_ai_summary.strip}

        Source: #{message[:permalink]}
      SUMMARY
    end

    context "with an invalid token" do
      it "warns about the error" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method! It's like #reduce, but easier to understand."}
        open_ai_error = "Incorrect API key provided: #{token}. You can find your API key at https://beta.openai.com."
        stub_open_ai_error(
          token: token,
          prompt: "Summarize this text: #{message[:text]}",
          response_error: open_ai_error
        )
        writer = described_class.new(open_ai_api_token: token, fallback_writer: stub_fallback_writer)

        expect {
          writer.summarize(message)
        }.to output("[WARNING] OpenAI error: #{open_ai_error}\n").to_stderr
      end

      it "uses the fallback writer to return a summary" do
        token = "invalid-token"
        message = {text: "Enumerable#each_with_object is a great method!"}
        stub_open_ai_error(
          token: token,
          prompt: "Summarize this text: #{message[:text]}",
          response_error: "Some error"
        )
        fallback_summary = "[TODO]"
        fallback_writer = stub_fallback_writer(summarize: fallback_summary)

        writer = described_class.new(open_ai_api_token: token, fallback_writer: fallback_writer)
        title = writer.summarize(message)

        expect(title).to eq(fallback_summary)
        expect(fallback_writer).to have_received(:summarize).with(message)
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
    stub_request(:post, "https://api.openai.com/v1/completions")
      .with(
        body: %({"model":"text-davinci-003","prompt":"#{prompt}","max_tokens":1000,"temperature":0}),
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
