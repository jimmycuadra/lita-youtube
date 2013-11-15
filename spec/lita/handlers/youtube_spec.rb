require "spec_helper"

JSON_RESPONSE = File.read(
  File.expand_path("../../../fixtures/success.json", __FILE__)
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
      response = double("Faraday::Response", status: 200, body: JSON_RESPONSE)

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(
        response
      )

      send_message("http://www.youtube.com/watch?v=dMH0bHeiRNg")
      expect(replies.last).to eq(
        "Evolution of Dance - By Judson Laipply (6m1s)"
      )
    end
  end

  describe "#short_link" do
    it "replies with the video's title and duration" do
      response = double("Faraday::Response", status: 200, body: JSON_RESPONSE)

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
