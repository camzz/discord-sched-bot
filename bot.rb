require 'discordrb'
require 'securerandom'
require 'time'

$command_prefix = :camzisawesome
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
Yes: #{@accepted.map(&:username).join(', ')}
No: #{@declined.map(&:username).join(', ')}
Maybe: #{@maybe.map(&:username).join(', ')}
    EOF
  end

  def accept(user)
    remove_user_from_lists(user)
    @accepted.push(user)
  end

  def decline(user)
    remove_user_from_lists(user)
    @accepted.push(user)
  end

  def maybe(user)
    remove_user_from_lists(user)
    @accepted.push(user)
  end

  private
  def remove_user_from_lists(user)
    @accepted.delete_if {|u| u.id == user.id }
    @declined.delete_if {|u| u.id == user.id }
    @maybe.delete_if {|u| u.id == user.id }
  end

end

def handle_create(event, args)
  id = SecureRandom.uuid
  name = args[1]
  time = Time.parse(args[2..-1].join(' '))
  if time < Time.now
    event.respond "Cannot create an event in the past"
  else
    $store[id] = Event.new(id, name, time)
    event.respond "New event #{name} scheduled for #{time}"
  end
end

def handle_list(event, args)
  $store.delete_if { |key, value| value.time < Time.now }
  if $store.empty?
    event.respond "There are no events currently scheduled"
  else
    event.respond $store.values.join("\n")
  end
end

def handle_yes(event, args)
  handle_missing(event, args) do |scheduled|
    scheduled.accept(event.user)
    nil
  end
end

def handle_no(event, args)
  handle_missing(event, args) do |scheduled|
    scheduled.decline(event.user)
    nil
  end
end

def handle_maybe(event, args)
  handle_missing(event, args) do |scheduled|
    scheduled.maybe(event.user)
    nil
  end
end

def handle_delete(event, args)
  handle_missing(event, args) do |scheduled|
    $store.delete(scheduled.id)
    nil
  end
end

def handle_responses(event, args)
  handle_missing(event, args) do |scheduled|
    scheduled.responses
  end
end

def handle_missing(event, args, &block)
  event_id = args[1]
  scheduled = $store[event_id]
  if scheduled
    event.respond block[scheduled]
  else
    event.respond "No event found with id #{event_id}"
  end
end

def handle_help(event, args)
  event.respond <<~EOF
Usage: !#{$command_prefix} <COMMAND> <ARGS>
where <COMMAND> one of:
list
  list all registered future events
create name time
  Create a new event at the given time
delete id
  Delete the event with the given id
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

bot = Discordrb::Commands::CommandBot.new token: '', client_id: 1, prefix: '!'

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.command $command_prefix do |event, *args|
  case args.first
  when 'create'
    handle_create(event, args)
  when 'delete'
    handle_delete(event, args)
  when 'list'
    handle_list(event, args)
  when /accept|yes/
    handle_yes(event, args)
  when /decline|no/
    handle_no(event, args)
  when 'maybe'
    handle_maybe(event, args)
  when 'help'
    handle_help(event, args)
  when 'responses'
    handle_responses(event, args)
  else event.respond "Command not recognised"
  end
end

bot.run
