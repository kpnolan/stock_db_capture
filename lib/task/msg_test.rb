class Foo < Struct.new(:payload, :decoded_args) do

    def method(transcode)
      meth = (transcode == :decode ? :decoded_args= : :payload=)
    end

    def initialize(payload, options)
      meth = method(options[:transcode])
      self.send(meth, payload)
    end
  end
end
