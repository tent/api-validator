module ApiValidator
  class Length < Base

    def initialize(path, length)
      initialize_assertions(path, length)
    end

    def validate(response)
      response_body = response.body.respond_to?(:to_hash) ? response.body.to_hash : response.body
      _failed_assertions = failed_assertions(response_body)
      super.merge(
        :key => :response_body,
        :failed_assertions => _failed_assertions.map(&:to_hash),
        :diff => diff(response_body, _failed_assertions),
        :valid => _failed_assertions.empty?
      )
    end

    private

    def initialize_assertions(path, size)
      @assertions = [Assertion.new(path, size, :type => :length)]
    end

    def failed_assertions(actual)
      assertions.select do |assertion|
        pointer = JsonPointer.new(actual, assertion.path)
        !pointer.exists? || !assertion_valid?(assertion, pointer.value)
      end
    end

    def diff(actual, _failed_assertions)
      _failed_assertions.map do |assertion|
        pointer = JsonPointer.new(actual, assertion.path)
        assertion = assertion.to_hash
        if pointer.exists?
          assertion[:op] = "replace"
          assertion[:current_value] = pointer.value.respond_to?(:length) ? pointer.value.length : 0
        else
          assertion[:op] = "add"
        end
        assertion
      end
    end

  end
end
