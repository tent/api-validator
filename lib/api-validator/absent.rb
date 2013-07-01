module ApiValidator
  class Absent < Base

    def initialize(*paths)
      initialize_assertions(paths)
    end

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

    def initialize_assertions(paths)
      @assertions = paths.map do |path|
        Assertion.new(path, nil, :type => :absent)
      end
    end

    def failed_assertions(actual)
      assertions.select do |assertion|
        pointer = JsonPointer.new(actual, assertion.path)
        pointer.exists?
      end
    end

    def diff(actual, _failed_assertions)
      _failed_assertions.map do |assertion|
        pointer = JsonPointer.new(actual, assertion.path)
        assertion = assertion.to_hash
        assertion[:op] = "remove"
        assertion[:current_value] = pointer.value
        assertion.delete(:type)
        assertion
      end
    end

  end
end
