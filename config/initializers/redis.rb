require "yaml"

# Redis Configuration
unless ENV['RACK_ENV'] == 'test'
  redis_settings = YAML::load_file("config/redis.yml")
  environment = ENV['RACK_ENV'] || 'production'
  REDIS = Redis.new(redis_settings[environment])
end
