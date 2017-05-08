require 'discordrb'
require 'securerandom'
require 'time'

$store = {}

class Event

  def initialize(id, name, time)
    @id = id
    @name = name
    @time = time
    @attendees = []
  end

  def to_s
    "#{@name}(ID #{@id}) scheduled for #{@time}"
  end

end

class Attendee

  def new()
  end

end

def handle_create(event, args)
  puts "Passed args #{args}"
  id = SecureRandom.uuid
  name = args[1]
  puts "Name is #{name}"
  time = Time.parse(args[2])
  $store[id] = Event.new(id, name, time)
  puts "Time is #{time}"
  puts "responding"
  event.respond "New event #{name} scheduled for #{time}"
end

def handle_list(event, args)
  event.respond $store.values.join('\r\n')
end

def handle_yes(event, args)
  event_id = args[1]

end

def handle_no(event, args)
  event_id = args[1]

end

def handle_maybe(event, args)

end

def handle_help(event, args)
  event.respond <<~EOF
Usage: !sched <COMMAND> <ARGS>
where <COMMAND> one of:
list
  list all registered future events
create name time
  Create a new event at the given time
accept|yes id
  Register for the event with the given id
decline|no id
  Decline the event with the given id
maybe
  Sit on the fence for the event with the given id (Don't be that guy!)
  EOF
end

# This statement creates a bot with the specified token and application ID. After this line, you can add events to the
# created bot, and eventually run it.
#
# If you don't yet have a token and application ID to put in here, you will need to create a bot account here:
#   https://discordapp.com/developers/applications/me
# If you're wondering about what redirect URIs and RPC origins, you can ignore those for now. If that doesn't satisfy
# you, look here: https://github.com/meew0/discordrb/wiki/Redirect-URIs-and-RPC-origins
# After creating the bot, simply copy the token (*not* the OAuth2 secret) and the client ID and put it into the
# respective places.
bot = Discordrb::Commands::CommandBot.new token: 'XXX', client_id: 311083321994248192, prefix: '!'

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.command :sched do |event, *args|
  puts args
  case args.first
  when 'create'
    handle_create(event, args)
  when 'list'
    handle_list(event, args)
  when /accept|yes/
    handle_yes(event, args)
  when /decline|no/
    handle_no(event, args)
  when 'help'
    handle_help(event, args)
  else event.respond "Command not recognised"
  end
end

bot.run
