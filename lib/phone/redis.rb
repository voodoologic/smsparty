module Phone
  class Redis
    attr_reader :redis, :users
    def initialize(url: nil)
      if url
        @redis = ::Redis.new(url: url)
      else
        @redis = ::Redis.new
      end
    end

    def method_missing(m, *args, &block)
      @redis.send(m, *args, &block)
    end

    def clean_house
      keys = @redis.keys
      @redis.del(*keys) unless keys.empty?
    end

    def find_by_phone_number(number)
      redis.mapped_hmget(number, :phone_number, :name, :role, :real_name, :subscription_level, :email, :token)
    end

    def all
      @redis.keys.map do |phone_number|
        redis.mapped_hmget(phone_number, :name, :phone_number, :role, :subscription_level, :email, :token)
      end
    end

    def remove_user(phone_number)
      @redis.del(phone_number)
    end

    def save_user(phone_user)
      @redis.mapped_hmset(phone_user.phone_number, phone_user.attributes_to_hash)
    end

  end
end
