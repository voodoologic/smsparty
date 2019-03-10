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
    user.token = 'blah'
    user.save
    refute_nil user.subscription_level
    assert user.phone_number
    assert user.token
  end

  it 'changes attrs' do
    user = Phone::User.new
    user.phone_number = '4155044070'
    user.name = 'Tommy'
    user.subscription_level = 'full'
    user.save
    assert_equal 'full', user.subscription_level
  end

end
