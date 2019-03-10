module Phone
  class User
    attr_accessor :name, :role, :real_name, :phone_number, :receives_messages, :email, :storage, :token
    def initialize
      @receives_messages = true
    end

    def self.all
      storage_array = storage.all
      storage_array.map do |hash|
        create_from_hash(hash)
      end
    end

    def receives_messages
      if @receives_messages == 'true' || @receives_messages == true
        true
      else
        false
      end
    end

    def self.find_by_name(name)
      all.detect do |user|
        user.name == name
      end
    end

    def self.find_by_token(token)
      all.detect do |user|
        user.token == token
      end
    end

    def self.find_by_phone_number(number)
      hash = storage.find_by_phone_number(number)
      create_from_hash(hash)
    end

    def storage
      @storage ||= Phone::Storage.new
    end

    def delete
      storage.remove_user(phone_number)
    end

    def self.storage
      storage ||= Phone::Storage.new
    end

    def boolean_receiveing_text(string_of_bool)
      string_of_bool == 'true' || string_of_bool == 'True'
    end

    def attributes_to_hash
      {
        name: name,
        role: role,
        phone_number: phone_number,
        receives_messages: receives_messages ,
        real_name: real_name,
        email: email,
        token: token,
      }
    end

    def self.create_from_hash(hash)
      new.tap do |user|
        hash.each do |key, value|
          value = nil if value == ''
          value = false if value == 'false'
          value = true if value == 'true'
          user.instance_variable_set(key.to_s.prepend('@'), value)
        end
        user.save
      end
    end

    def save
      storage.save_user(self)
    end
  end
end
