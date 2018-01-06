module Phone
  class Storage < Delegator
    attr_reader :adapter, :users
    def initialize(storage_adapter: Phone::Redis.new)
      super
      @storage_adapter = storage_adapter
    end

    def __getobj__()
      @storage_adapter
    end

    def __setobj__(storage_adapter)
      @storage_adapter = storage_adapter
    end
  end
end
