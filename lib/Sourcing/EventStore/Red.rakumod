use Sourcing::EventStore;
use Red:api<2> <refreshable>;
use Red::Driver;
use Red::Type::Json;
unit class Sourcing::EventStore::Red does Sourcing::EventStore;

has Str         $.driver = "SQLite";
has             %.pars;
has Red::Driver $.db = database $!driver, |%!pars;

model EventField {...}
model EventClass {...}
model Event is table<event> {
	has UInt       $.id        is serial;
	has Instant()  $.timestamp is column = now;
	has Str        $.type      is column;
	has Json       $.data      is column;
	has EventField @.fields    is relationship{ .event-id };

	method to-event {
		my $t = ::($.type);
		if !$t && $t ~~ Failure {
			require ::($.type);
			$t = ::($.type);
		}
		$*SOURCING-MESSAGE-SEQ = $.id if $*SOURCING-MESSAGE-SEQ !~~ Failure;
		$t.new: |$.data
	}
}

model EventField is table<field> {
	has UInt  $.event-id is column{ :id, :references{ .id }, :model-type(Event) };
	has Str   $.field    is required is id;
	has       $.value    is column{ :id, :nullable };
	has Event $.event    is relationship{ .event-id };
}

model EventClass is table<type> {
	has Str $.type  is id;
	has Str $.parent is id;
}

method TWEAK(|) {
	my $*RED-DB = $!db;
	Event.^create-table: :unless-exists;
	EventField.^create-table: :unless-exists;
	EventClass.^create-table: :unless-exists;
}

method add-event(Sourcing::Event $event) {
	my $*RED-DB = $!db;

	red-do :transaction, {
		my $type = $event.^name;
		my %data = $event.^attributes.grep(*.has_accessor).map: { .name.substr(2) => .get_value: $event }

		my $entry = Event.^create: :$type, :%data;

		my @type = (|$event.^mro, |$event.^roles).map( *.^name ).grep: { $_ ne <Any Mu>.any };
		unless EventClass.^all.first: { .type eq $type } {
			for @type -> $parent {
				EventClass.^create: :$type, :$parent
			}
		}

		for %data.kv -> Str $field, $value {
			EventField.^create: :event-id($entry.id), :$field, :$value
		}

		$entry.^refresh.to-event
	}
}

method get-events(Int $index = -1, :@types, Instant :$from-timestamp, Instant :$to-timestamp, *%pars) {
	my $*RED-DB = $!db;

	my $events = do if %pars {
		my $fields = EventField.^all;
		for %pars.kv -> $key, $value {
			FIRST {
				$fields .= grep: {
					.field eq $key
					&& .value eqv $value
				}
				next
			}
			$fields .= join-model:
				:name("field_$key"),
				EventField, -> $prev, $field {
					$prev.event-id == $field.event-id
					&& $field.field eq $key
					&& $field.value eqv $value
				}
		}
		$fields.map: { .event }
	} else {
		Event.^all
	}

	$events .= grep(*.id > $index);

	if @types {
		$events .= grep: { .type in EventClass.^all.grep({ .parent in @types }).map: *.type };
	}

	with $from-timestamp -> $from {
		$events .= grep: { .timestamp > $from }
	}

	with $to-timestamp -> $to {
		$events .= grep: { .timestamp <= $to }
	}

	my @events = $events.sort(*.id).Seq;

	@events.map: {
		.to-event
	}
}
