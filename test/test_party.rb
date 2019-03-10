require_relative "spec_helper"
require_relative "../party.rb"


def app
  Party
end

describe Party do
  def setup
    Phone::Storage.new.clean_house
  end

  it "processes a command" do
    test_params['Body'] = "~add tommy:5557778888"
    post '/', test_params
    refute_nil(last_response.body)
  end
end

describe Phone::Storage do
  let(:app_instance) do
    p = Party.allocate
    p.send(:initialize)
    p
  end

  let(:users) { Phone::User.all }
  after do
    Phone::Storage.new.clean_house
    test_params['Body'] = 'message'
  end

  before do
    tommy = Phone::User.new
    tommy.name = 'tommy😜'
    tommy.phone_number = '+14155044070'
    billy = Phone::User.new
    billy.name = 'billy'
    billy.phone_number = '+12061115555'
    jimmy = Phone::User.new
    jimmy.name = 'jimmy'
    jimmy.phone_number = '+14152223333'
    [tommy, billy, jimmy].each(&:save)
  end

  it 'add a new user' do
    refute_nil(users)
  end

  it 'packages a user in a class' do
    assert_kind_of Phone::User, users.first
  end

  it 'creates a one-time admin token to consume' do
    test_params['Body'] = '~admin'
    post '/publish', test_params
    assert users
  end
  it 'deletes a user from list' do
    test_params['Body'] = '~remove tommy😜'
    test_params['From'] = '+141555555555'
    assert_equal Phone::User.all.count, 3
    post '/publish', test_params
    assert_equal Phone::User.all.count, 2
  end

  it 'lets a user stop messages' do
    test_params['Body'] = '~stop'
    test_params['From'] = '+14155044070'
    $debug = true
    post '/publish', test_params
    user = Phone::User.find_by_name('tommy😜')
    $debug = false
    assert_equal 'important', user.subscription_level
  end

  it 'lets a user start messages' do
    test_params['Body']= '~start'
    post '/publish', test_params
    user = Phone::User.find_by_name('tommy😜')
    assert_equal 'full', user.subscription_level
  end

  it 'starts a user receiving messages' do
    test_params['Body'] = '~start tommy😜'
    app_instance.do_the_right_thing(test_params)
    user = users.first
    assert_equal 'full', user.subscription_level
  end

  it 'stops a user recieving messages' do
    test_params['Body'] = '~stop tommy😜'
    post '/publish', test_params
    user = users.first
    assert_equal 'important', user.subscription_level
  end

  it 'creates a token' do
    test_params['Body'] = '~admin'
    post '/publish', test_params
    user = users.first
    assert user.token
  end

  it 'messages other users' do
    test_params['Body'] = 'message'
    user = Phone::User.all.first
    user.subscription_level = 'full'
    user.save
    post '/publish', test_params
  end

  it 'displays the help menu' do
    test_params['Body'] = '~help'
    post '/publish', test_params

  end

end

def test_params
  @test_params ||= {
    "ToCountry"=>"US",
    "ToState"=>"WA",
    "SmsMessageSid"=>"SM6e7c624b510d6203ac50c077ecb3b110",
    "NumMedia"=>"0",
    "ToCity"=>"",
    "FromZip"=>"94131",
    "SmsSid"=>"SM6e7c624b510d6203ac50c077ecb3b110",
    "FromState"=>"CA",
    "SmsStatus"=>"received",
    "FromCity"=>"SAN FRANCISCO",
    "Body"=>"Message",
    "FromCountry"=>"US",
    "To"=>"+12068008190",
    "ToZip"=>"",
    "NumSegments"=>"1",
    "MessageSid"=>"SM6e7c624b510d6203ac50c077ecb3b110",
    "AccountSid"=>"AC29eaa09f33b68ee312e1ba33cb64a5f7",
    "From"=>"+14155044070",
    "ApiVersion"=>"2010-04-01"
  }
end
