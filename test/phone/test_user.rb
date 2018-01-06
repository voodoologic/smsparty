require_relative "../spec_helper"
require_relative "../../party.rb"


def app
  Party
end
describe Phone::User do
  before do
    Phone::Redis.new.clean_house
  end

  it 'is a thing' do
    assert Phone::User
  end

  it 'saves attrs' do
    user = Phone::User.new
    user.phone_number = '4155044070'
    user.save
    assert user.receives_messages
    assert user.phone_number
  end

  it 'changes attrs' do
    user = Phone::User.new
    user.phone_number = '4155044070'
    user.name = 'Tommy'
    user.receives_messages = false
    user.save
    refute user.receives_messages
    refute Phone::User.all.first.receives_messages
  end

end
