require 'discordrb'
require 'securerandom'
require 'time'

$store = {}

class Event

  attr_reader :id, :name, :time, :accepted, :declined, :maybe

  def initialize(id, name, time)
    @id = id
    @name = name
    @time = time
    @accepted = []
    @declined = []
    @maybe = []
  end

  def to_s
    "#{@id}: #{@name} scheduled for #{@time}"
  end

  def responses
    <<~EOF
Yes: #{@accepted.join(', ')}
No: #{@declined.join(', ')}
Maybe: #{@maybe.join(', ')}
    EOF
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
  scheduled = $store[event_id]
  if scheduled
    scheduled.accepted.push(event.user.username)
  else
    event.respond "No event found with id #{event_id}"
  end
end

def handle_no(event, args)
  event_id = args[1]
  scheduled = $store[event_id]
  if scheduled
    scheduled.declined.push(event.user.username)
  else
    event.respond "No event found with id #{event_id}"
  end
end

def handle_maybe(event, args)
  event_id = args[1]
  scheduled = $store[event_id]
  if scheduled
    scheduled.maybe.push(event.user.username)
  else
    event.respond "No event found with id #{event_id}"
  end
end

#TODO extract this logic to method which takes block
##TODO accepting should remove from list of declines if necessary
def handle_responses(event, args)
  event_id = args[1]
  scheduled = $store[event_id]
  if scheduled
    event.respond scheduled.responses
  else
    event.respond "No event found with id #{event_id}"
  end
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
responses
  List the responses to the event (yes, no, maybe)
  EOF
end

bot = Discordrb::Commands::CommandBot.new token: '', client_id: 311083321994248192, prefix: '!'

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
  when 'responses'
    handle_responses(event, args)
  else event.respond "Command not recognised"
  end
end

bot.run
