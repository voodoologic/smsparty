secrets = YAML.load_file('./secrets.yml')
ACCOUNT_SID=secrets.fetch('account_sid', ENV['ACCOUNT_SID'])
AUTH_TOKEN=secrets.fetch('auth_token', ENV['AUTH_TOKEN'])
PHONE_NUMBER=secrets.fetch('phone_number', ENV['PHONE_NUMBER'])
USERS=secrets.fetch('users', [])
DOMAIN=secrets.fetch('domain', ENV['DOMAIN'])
require 'securerandom'

Phonelib.default_country = "US"

class Party < Sinatra::Base
  attr_reader :users, :storage
  def client
    @client ||= Twilio::REST::Client.new(ACCOUNT_SID, AUTH_TOKEN)
  end

  def storage
    @storage ||= Phone::Storage.new
  end

  set :public_folder => "public", :static => true
  set :bind, '0.0.0.0'

  get '/' do
    erb :welcome, layout: :layout
  end

  post '/publish' do
    redirect 'https://www.youtube.com/watch?v=XqZsoesa55w' unless params.keys.include?('From')

    do_the_right_thing(params)
  end

  get '/users' do
    @users = Phone::User.all
    erb :users, layout: :layout
  end

  get '/users/:token' do
    redirect 'https://www.youtube.com/watch?v=XqZsoesa55w' unless params.keys.include?('token')
    token = params.fetch('token')
    @user = Phone::User.find_by_token(token)
    erb :user, layout: :layout
  end

  post '/users' do
    token = params.fetch('token')
    subscription_level = params.fetch('subscription_level')
    name = params.fetch('name')
    @user = Phone::User.find_by_token(token)
    @user.name = name
    @user.subscription_level = subscription_level
    @user.token = nil
    @user.save
  end

  def do_the_right_thing(message_params)
    if message_params.fetch('Body').match(/^\~/)
      process_command(message_params)
    else
      message_all_others(message_params)
    end
  rescue => e
    puts e
    send_message "+14155044070", e
  end

  def process_command(message_params)
    command = message_params.fetch('Body').match(/\~(?<command>\w+) *(?<name>.*)/)[:command]
    case command
    when "add"
      add_user(message_params)
    when "stop"
      stop_user_receiving(message_params)
    when "start"
      start_user_receiving(message_params)
    when "help"
      show_help(message_params)
    when "remove"
      remove_user(message_params)
    when 'list'
      list_users(message_params)
    when 'name'
      change_name(message_params)
    when 'admin'
      process_admin(message_params)
    end
  end

  def change_name(message_params)
    phone_number = message_params.fetch('From')
    user = Phone::User.find_by_phone_number(phone_number)
    _, name  = disect_command_and_name(message_params)
    user.name = name
    user.save
    send_message message_params.fetch('From'), 'success'
  end

  def process_admin(message_params)
    phone_number = message_params.fetch('From')
    user = Phone::User.find_by_phone_number(phone_number)
    create_token_for_user(user)
    url = create_url(user).to_s
    send_message phone_number, "visit admin: #{url}"
  end

  def create_url(user)
    URI::HTTP.build(
      { host: DOMAIN, path: "/users/#{user.token}" }
    )
  end

  def create_token_for_user(user)
    user.token = SecureRandom.uuid
    user.save
  end

  def list_users(message_params)
    phone_number = Phonelib.parse(message_params.fetch('From')).to_s
    body = ''
    Phone::User.all.each do |user|
      body << "#{user.name} - #{Phonelib.parse(user.phone_number).national}\n"
    end
    send_message(phone_number, body)
  end

  def show_help(message_params)
    phone_number = Phonelib.parse(message_params.fetch('From')).to_s
    body = <<-EOF.gsub(/^ */, '')
      ~help display this message
      ~stop stop messages from flowing
      ~start start messages flowing
      ~name change your name
      ~admin link to admin page
    EOF
    send_message(phone_number, body)
  end

  def start_user_receiving(message_params)
    _, name  = disect_command_and_name(message_params)
    if name
      user = Phone::User.find_by_name(name)
    else
      phone_number = message_params.fetch('From')
      user = Phone::User.find_by_phone_number(phone_number)
    end
    user.subscription_level = 'full'
    user.save
    send_message message_params.fetch('From'), 'receiving messages'
  end

  def stop_user_receiving(message_params)
    _, name  = disect_command_and_name(message_params)
    if name
      user = Phone::User.find_by_name(name)
    else
      phone_number = message_params.fetch('From')
      user = Phone::User.find_by_phone_number(phone_number)
    end
    user.subscription_level = 'important'
    user.save
    send_message message_params.fetch('From'), 'successully stoped mesages'
  end

  def message_important_subscriptions(full_recipients, message_params)
    full_recipients.select do |user|
      user.subscription_level && ['full', 'alerts']
    end
  end

  def message_all_others(message_params)
    users = receivable_users(message_params)
    from_number = Phonelib.parse(message_params.fetch('From'))
    from_user = Phone::User.find_by_phone_number(from_number.to_s)
    message = message_params.fetch('Body').prepend("#{from_user.name}: ")
    media = get_media(message_params)
    users.each do |user|
      send_message(user.phone_number, message, media)
    end
  end

  def get_media(message_params)
    message_params.select do |key, value|
      key =~ /^MediaUrl\d/
    end.values
  end

  def send_message(phone_number, body, media = [])
    if media.size == 0
      sms_send(phone_number, body)
    else
      mms_send(phone_number, body, media)
    end
  end

  def mms_send(phone_number, body, media_url)
    return if ENV['RACK_ENV'] == 'test'
    account = client.api.account
    account.messages.create(
      from: PHONE_NUMBER,
      to: phone_number,
      body: body,
      media_url: media_url
    )
  rescue => e
    puts e
    binding.pry
  end

  def sms_send(phone_number, body)
    return if ENV['RACK_ENV'] == 'test'

    account = client.api.account
    account.messages.create(
      from: PHONE_NUMBER,
      to: phone_number,
      body: body
    )
  rescue => e
    puts e
    binding.pry
  end

  def receivable_users(message_params)
    message = message_params.fetch('Body')
    message_importance = message.match(/^\!/)
    full_recipients = exclude_sender(message_params)
    if message_importance
      message_important_subscriptions(full_recipients, message_params)
    else
      message_active_participants(full_recipients, message_params)
    end
  end

  def message_active_participants(full_recipients, message_params)
    full_recipients.select do |user|
      user.subscription_level == 'full' && user.phone_number != message_params.fetch('From')
    end
  end

  def exclude_sender(message_params)
    Phone::User.all.reject do |user|
      user.phone_number == message_params.fetch('From')
    end
  end

  def add_user(message_params)
    _, name, phone_number  = disect_message(message_params)
    u = Phone::User.new
    u.name = name
    u.phone_number = phone_number
    u.save
  end

  def remove_user(message_params)
    _, name  = disect_command_and_name(message_params)
    user = Phone::User.find_by_name(name)
    user.delete
  end

  def disect_command_and_name(message_params)
    match = message_params.fetch('Body').match(/^\~(?<command>\w+)$/)
    return [match[:command], nil] if match
    match = message_params.fetch('Body').match(/\~(?<command>\w+) *(?<name>.+)/)
    command = match[:command]
    name    = match[:name]
    [command, name]
  end

  def disect_message(message_params)
    match = message_params.fetch('Body').match(/\~(?<command>\w+) +(?<name>\w+):(?<number>.+)/)
    command = match[:command]
    name    = match[:name]
    number  = match[:number]
    number_validator = Phonelib.parse(number)
    if number_validator.valid?
      number = number_validator.to_s
      [command , name , number ]
    else
      throw :command_error
    end
  end
end

unless ENV['RACK_ENV'] == 'test'
  USERS.each do |name_phone|
    user = Phone::User.new
    user.name = name_phone.fetch('name')
    user.phone_number = name_phone.fetch('phone')
    user.save
  end
end
