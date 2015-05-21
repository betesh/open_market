module OpenMarket
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end

  class Configuration
    class Error < ::StandardError; end
    CONFIGURATION_OPTIONS = [:id, :password, :program_id, :short_code]

    (CONFIGURATION_OPTIONS - [:short_code]).each do |accessor|
      define_method(:"#{accessor}=") do |arg|
        raise Error, "#{accessor} must be a String" unless arg.nil? || arg.is_a?(String)
        raise Error, "#{accessor} cannot be blank" if arg.nil? || arg.empty?
        instance_variable_set("@#{accessor}", arg)
      end
    end

    def short_code=(arg)
      raise Error, "short_code cannot be blank" if arg.nil?
      raise Error, "short_code must be a 5-digit number" unless arg.to_s.scan(/\A[0-9]{5}\z/)
      @short_code = arg
    end

    CONFIGURATION_OPTIONS.each do |accessor|
      define_method(accessor) do
        instance_variable_get("@#{accessor}").tap do |result|
          raise Error, "#{accessor} has not been set.  Set it with `#{Module.nesting.last}.configuration.#{accessor} = ...`" if result.nil?
        end
      end
    end
  end
end
