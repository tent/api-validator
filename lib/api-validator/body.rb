module ApiValidator
  class Body < Base

    def validate(response)
      response_body = read_response_body(response)
      _failed_assertions = failed_assertions(response_body)
      super.merge(
        :key => :response_body,
        :failed_assertions => _failed_assertions.map(&:to_hash),
        :diff => diff(response_body, _failed_assertions),
        :valid => _failed_assertions.empty?
      )
    end

    private

    def initialize_assertions(body)
      @assertions = [Assertion.new("", body)]
    end

    def failed_assertions(actual)
      assertions.select do |assertion|
        !assertion_valid?(assertion, actual)
      end
    end

    def diff(actual, _failed_assertions)
      _failed_assertions.map do |assertion|
        assertion = assertion.to_hash
        assertion[:op] = "replace"
        assertion[:current_value] = actual
        assertion
      end
    end

  end
end
