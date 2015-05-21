require "yaml"
require "logger"
require "rspec/core/shared_context"
require "sms_validation"

module ConfigurationFromYaml
  extend RSpec::Core::SharedContext
  SECRETS = YAML::load(File.open(File.expand_path("#{__FILE__}/../secrets.yml")))

  SECRETS.keys.each do |key|
    let(key) { SECRETS[key] }
  end

  let(:skip_open_market_configuration) { false }

  before(:each) do
    SmsValidation.configure do |config|
      config.logger = ::Logger.new(STDOUT)
    end
    OpenMarket.configure do |config|
      config.id, config.password, config.short_code, config.program_id = id, password, short_code, program_id
    end unless skip_open_market_configuration
  end

  after(:each) do
    OpenMarket.instance_variable_set("@configuration", nil)
    SmsValidation.instance_variable_set("@configuration", nil)
  end
end

RSpec.configure do |config|
  config.include ConfigurationFromYaml
end
