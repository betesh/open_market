require "bundler/gem_tasks"

namespace :openmarket do
  desc "Get status of a ticket (Usage: TICKET_ID=... rake openmarket:status).  Uses your test credentials."
  task :status do
    require "open_market/api"
    require "logger"
    SmsValidation.configure do |config|
      config.logger = ::Logger.new(STDOUT)
    end
    OpenMarket.configure do |config|
      secrets = YAML::load(File.open(File.expand_path("#{__FILE__}/../spec/support/secrets.yml")))
      config.id, config.password, config.short_code, config.program_id = secrets['id'], secrets['password'], secrets['short_code'], secrets['program_id']
    end
    puts OpenMarket::API.status(ENV['TICKET_ID']).inspect
  end
end
