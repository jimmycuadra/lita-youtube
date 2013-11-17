require "spec_helper"

SUCCESS_JSON = File.read(
  File.expand_path("../../../fixtures/success.json", __FILE__)
).chomp

LONG_DURATION_JSON = File.read(
  File.expand_path("../../../fixtures/long_duration.json", __FILE__)
).chomp

SHORT_DURATION_JSON = File.read(
  File.expand_path("../../../fixtures/short_duration.json", __FILE__)
).chomp

describe Lita::Handlers::Youtube, lita_handler: true do
  it { routes("http://www.youtube.com/watch?v=dMH0bHeiRNg").to(:query_string) }
  it { routes("https://www.youtube.com/watch?v=dMH0bHeiRNg").to(:query_string) }

  it do
    routes(
      "http://www.youtube.com/watch?feature=player_embedded&v=dMH0bHeiRNg"
    ).to(:query_string)
  end

  it do
    routes(
      "check this out! http://www.youtube.com/watch?v=dMH0bHeiRNg - it's great!"
    ).to(:query_string)
  end

  it { routes("http://youtu.be/dMH0bHeiRNg").to(:short_link) }
  it { routes("https://youtu.be/dMH0bHeiRNg").to(:short_link) }

  describe "#query_string" do
    it "replies with the video's title and duration" do
      response = double("Faraday::Response", status: 200, body: SUCCESS_JSON)

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
        response
      )

      send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
      expect(replies.last).to eq(
        "Evolution of Dance - By Judson Laipply (6m1s)"
      )
    end

    it "correctly formats durations longer than an hour" do
      response = double(
        "Faraday::Response",
        status: 200,
        body: LONG_DURATION_JSON
      )

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
        response
      )

      send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
      expect(replies.last).to eq(
        "Evolution of Dance - By Judson Laipply (1h15m32s)"
      )
    end

    it "correctly formats durations of less than a minute" do
      response = double(
        "Faraday::Response",
        status: 200,
        body: SHORT_DURATION_JSON
      )

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
        response
      )

      send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
      expect(replies.last).to eq(
        "Evolution of Dance - By Judson Laipply (25s)"
      )
    end

    context "when the API returns a non-200 status" do
      let(:response) { double("Faraday::Response", status: 500) }

      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
          response
        )
      end

      it "logs an error" do
        expect(Lita.logger).to receive(:error).with(
          "YouTube API returned status code 500."
        )
        send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
      end

      it "doesn't send any messages to the chat" do
        send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
        expect(replies).to be_empty
      end
    end
  end

  describe "#short_link" do
    it "replies with the video's title and duration" do
      response = double("Faraday::Response", status: 200, body: SUCCESS_JSON)

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
        response
      )

      send_message("http://youtu.be/dMH0bHeiRNg")
      expect(replies.last).to eq(
        "Evolution of Dance - By Judson Laipply (6m1s)"
      )
    end
  end
end
