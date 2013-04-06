class HashWrapper
  attr_reader :hash
  def initialize(hash)
    hash.default_proc = lambda { |hash, key|
      key = (Symbol === key) ? key.to_s : key.to_sym
      hash.has_key?(key) ? hash[key] : nil
    }
    @hash = hash
  end

  def has_key?(key)
    hash.has_key?(key.to_s) || hash.has_key?(key.to_sym)
  end

  def [](key)
    hash[key]
  end

  def []=(key, val)
    hash[key.to_sym] = val
  end

  def ==(other)
    hash == other
  end

  def to_hash(options = {})
    hash
  end

  def respond_to_missing?(method)
    has_key?(method) || method =~ /=\Z/ || hash.respond_to?(method)
  end

  def method_missing(method, *args, &block)
    if respond_to_missing?(method)
      if has_key?(method)
        val = self.send(:[], method, *args, &block)
        val = self.class.new(val) if Hash === val
        val
      elsif method =~ /=\Z/
        self.send(:[]=, method.to_s.sub(/=\Z/, ''), *args, &block)
      else
        hash.send(method, *args, &block)
      end
    else
      super
    end
  end
end
