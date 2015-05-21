require "yaml"
require "logger"
require "rspec/core/shared_context"

module ConfigurationFromYaml
  extend RSpec::Core::SharedContext
  SECRETS = YAML::load(File.open(File.expand_path("#{__FILE__}/../secrets.yml")))

  SECRETS.keys.each do |key|
    let(key) { SECRETS[key] }
  end
end

RSpec.configure do |config|
  config.include ConfigurationFromYaml
end
