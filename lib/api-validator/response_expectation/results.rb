module ApiValidator
  class ResponseExpectation

    class Results
      include Mixins::DeepMerge

      attr_reader :response, :results
      def initialize(response, results)
        @response, @results = response, results
      end

      def as_json(options = {})
        res = merge_keys(results)
        merge_diffs!(res)

        {
          :expected => res,
          :actual => {
            :request_headers => response.env[:request_headers],
            :request_body => response.env[:request_body],
            :request_path => response.env[:url] ? response.env[:url].path : nil,
            :request_params => parse_params(response.env[:url]),
            :request_url => response.env[:url].to_s,
            :request_method => response.env[:method].to_s.upcase,

            :response_headers => response.headers,
            :response_body => read_response_body(response),
            :response_status => response.status
          }
        }
      end

      private

      def read_response_body(response)
        body = response.body
        if body.respond_to?(:read)
          _body = body.read
          body.rewind if body.respond_to?(:rewind)
          _body
        elsif body.respond_to?(:to_hash)
          body.to_hash
        else
          body
        end
      end

      # TODO: handle multiple params of same name
      def parse_params(uri)
        return unless uri && uri.query
        uri.query.split('&').inject({}) do |params, part|
          key, value = part.split('=')
          params[key] = value
          params
        end
      end

      def merge_keys(results)
        results.inject(Hash.new) do |memo, result|
          result = result.dup
          deep_merge!((memo[result.delete(:key)] ||= Hash.new), result)
          memo
        end
      end

      def merge_diffs!(expectation_results)
        expectation_results.each_pair do |key, results|
          results[:diff] = results[:diff].inject({}) do |memo, diff|
            (memo[diff[:path]] ||= []) << diff
            memo
          end.inject([]) do |memo, (path, diffs)|
            memo << diffs.sort_by { |d| d[:value].to_s.size * -1 }.first
          end.sort_by { |d| d[:path].split("/").size }
        end
      end
    end

  end
end
