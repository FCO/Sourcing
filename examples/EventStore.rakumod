no precompilation;
unit class EventStore;

has @.events;

method new {!!!}
method instance { $ //= ::?CLASS.bless }

method add-event($event) {
	@!events.push: $event
}

method query($query) {
	@!events.grep: { $query.^expects-event: $_ }
}
