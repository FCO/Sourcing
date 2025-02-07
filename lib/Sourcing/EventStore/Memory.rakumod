use Sourcing::EventStore;
use Red;
use Red::Type::Json;
unit class Sourcing::EventStore::Memory does Sourcing::EventStore;

has $.db = database "SQLite";

model Event is table<event> {
	has UInt    $.id        is serial;
	has Instant $.timestamp is column = now;
	has Str     $.type      is column;
	has Json    $.data      is column;
}

#model EventField is table<field> {
#	has UInt $.event-id is column{ :id, :references{ .id }, :model-type(Event) };
#	has Str  $.field    is required is id;
#	has      $.value    is column{ :id, :nullable };
#}

method TWEAK(|) {
	my $*RED-DB = $!db;
	Event.^create-table: :unless-exists;
	#EventField.^create-table: :unless-exists;
}

method add-event(Sourcing::Event $event) {
	my $*RED-DB = $!db;

	red-do :transaction, {
		my %data = $event.^attributes.grep(*.has_accessor).map: { .name.substr(2) => .get_value: $event }
		my $entry = Event.^create: :type($event.^name), :%data;

		#for %data.kv -> Str $field, $value {
		#	EventField.^create: :event-id($entry.id), :$field, :$value
		#}

		$entry.id
	}
}

method get-events(Int $index = -1, Instant :$from-timestamp, Instant :$to-timestamp, *%pars) {
	my $*RED-DB = $!db;
	my $events = Event.^all.grep(*.id > $index);
	with $from-timestamp -> $from {
		$events .= grep: { .timestamp > $from }
	}
	with $to-timestamp -> $to {
		$events .= grep: { .timestamp <= $to }
	}
	if %pars {
		for %pars.kv -> $key, $value {
			$events .= grep: { .data{$key} == $value }

			#$events .= join-model:
			#	:name($key),
			#	EventField, -> \event, \field {
			#		event.id == field.event-id
			#		&& field.field eq $key
			#		&& field.value == $value
			#	}
		}
	}
	my @events = $events.Seq;
	@events.map: {
		require ::(.type);
		::(.type).new: |.data
	}
}
