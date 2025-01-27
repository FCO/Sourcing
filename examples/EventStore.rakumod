no precompilation;
unit class EventStore;

has @.events;

method new {!!!}
method instance { $ //= ::?CLASS.bless }

method add-event($event) {
	@!events.push: $event
}

method query($query) {
	CATCH {
		default {
			.say
		}
	}
	say $query;
	my $projection = $query<projection>.new;
	my $id-field = $projection.^is-aggregated-by;
	for @!events.grep: { $_ ~~ any($query<event-classes>) && ."$id-field"() eqv $query<id> } -> $event {
		$projection.apply: $event
	}
	$query<response>.keep: $projection
}
