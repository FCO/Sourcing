use v6.e.PREVIEW;
use Sourcing;
unit projection Sourcing::Manager;

#use Sourcing::EventStore::Red;
use Sourcing::Event;
use Sourcing::Projection;
use Sourcing::EventStore;

has %.events;
has %.instances;

has Lock::Async $!manager-lock .= new;

method TWEAK(|) {
	Supply.interval(1).tap: {
		for %!instances.values -> $value {
			$!manager-lock.protect: {
				next without $value<instances>;
				if process-path($value<instances>) {
					$value<instances>:delete
				}
			}
		}
	}
	nextsame;
}

multi process-path(Sourcing::Projection $proj) {
	$proj.should-it-be-killed: DateTime.now
}

multi process-path(%node where { .elems == 1 }) {
	for %node.kv -> $key, $value {
		if process-path($value) {
			%node{$key}:delete;
			return True
		}
	}
	False
}

multi process-path(%node) {
	for %node.kv -> $key, $value {
		if process-path($value) {
			%node{$key}:delete;
		}
	}
	False
}

method get(::T $type is copy, *%values --> T) is query {
	self._receive-events;
	$type = .^name without $type;

	my :(:$class, :%instances) := %!instances{$type};

	my @ids = |$class.^aggregation-ids-names, |$class.^projection-arg-names;

	my @values = @ids.map: { %values{$_} }

	%instances{||@values} //= $class.new: |%values
}

multi method register-class(Sourcing::Projection $proj) {
	$!manager-lock.protect: {
		my @ids = $proj.^aggregation-ids-attrs.map: *.name.substr: 2;
		%!instances{$proj.^name}<class> = $proj;
		for $proj.^applyable-events -> $event {
			%!events.push: $event.^name => $proj
		}
	}
}

multi method apply(Sourcing::Event $event) {
	my @classes = gather for |$event.^mro, |$event.^roles -> $parent {
		for %!events{ $parent.^name } {
			.take with %!instances{.^name}
		}
	};
	die "Unexpected event $event.raku() (@classes[])" unless @classes;
	for @classes <-> %item (:$class!, :%instances, |) {
		my @agg = $class.^aggregation-ids-from-event: $event;
		my %agg is Map = $class.^aggregation-ids-map-from-event: $event;
		my @arg = #class.^projection-arg-from-event: $event;
		my %arg is Map = $class.^projection-arg-map-from-event: $event;
		my @path = |@agg, |@arg;
		my $instance = %instances{||@path} //= $class.new: |%agg, |%arg;
		$!manager-lock.protect: { %item<instances> = %instances }
		#$instance.receive-events
	}
}
