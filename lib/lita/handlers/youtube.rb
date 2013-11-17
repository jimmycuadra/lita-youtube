require "lita"

module Lita
  module Handlers
    # Listen for YouTube links and respond with their titles and duration.
    class Youtube < Handler
      API_URL = "http://gdata.youtube.com/feeds/api/videos/"

      route(%r{(https?://www\.youtube\.com\/watch\?[^\s]+?)}i, :query_string)
      route(%r{(https?://youtu\.be/)([a-z0-9\-_]+)}i, :short_link)

      def query_string(response)
        video_id = extract_video_id(response.matches[0][0])
        get_video_data_and_respond(video_id, response)
      end

      def short_link(response)
        get_video_data_and_respond(response.matches[0][1], response)
      end

      private

      def get_video_data_and_respond(video_id, response)
        title, time = video_data(video_id)

        if title && time
          response.reply "#{title} (#{time})"
        end
      end

      def extract_video_id(url)
        url = URI.parse(url)
        Rack::Utils.parse_nested_query(url.query)
      end

      def video_data(video_id)
        Lita.logger.info("Requesting data for YouTube video #{video_id}.")

        response = http.get("#{API_URL}#{video_id}", alt: "json")

        if response.status == 200
          data = MultiJson.load(response.body)
          entry = data["entry"]
          title = entry["title"]["$t"]
          time = format_time(entry["media$group"]["yt$duration"]["seconds"])
          [title, time]
        else
          Lita.logger.error(
            "YouTube API returned status code #{response.status}."
          )
        end
      end

      def format_time(seconds)
        minutes, seconds = seconds.to_i.divmod(60)
        hours, minutes = minutes.divmod(60)

        if hours > 0
          "#{hours}h#{minutes}m#{seconds}s"
        elsif minutes > 0
          "#{minutes}m#{seconds}s"
        else
          "#{seconds}s"
        end
      end
    end

    Lita.register_handler(Youtube)
  end
end
