use v6.e.PREVIEW;
use Sourcing;
unit process Sourcing::Manager;

use Sourcing::Event;
use Sourcing::Projection;
use Sourcing::EventStore;

has %.events;
has %.instances;

has Lock::Async $!manager-lock .= new;

event ProjectionObjectCreated {
	has Str $.type is required;
	has     %.data;
}

event ProjectionRegistred {
	has Str $.type;
}

#method TWEAK(|) {
#	Supply.interval(1).tap: {
#		for %!instances.values -> $value {
#			$!manager-lock.protect: {
#				next without $value<instances>;
#				if process-path($value<instances>) {
#					$value<instances>:delete
#				}
#			}
#		}
#	}
#	nextsame;
#}

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

method get(::T $type, *%values --> T) is query {
	self._get: $type, |%values
}

method _get(::T $type is copy, *%values --> T) {
	$type = .^name without $type;

	self._receive-events;

	die "No entry for $type" unless %!instances{$type}:exists;
	my :(:$class, :%instances) := %!instances{$type};

	my @ids = |$class.^aggregation-ids-names, |$class.^projection-arg-names;

	my @values = @ids.map: { %values{$_} }

	my $instance = %instances{||@values};

	with $instance {
		.receive-events;
		.return
	}
	T
}

multi method register-class(Mu:U $type) {
	$.register-class: $type.^name
}

multi method register-class(Str $type) is command {
	die "Class $type already registred" with %!instances{$type}; 
	$.projection-registred: :$type
}

multi method apply(ProjectionRegistred $_) {
	#say "apply";
	my $proj = ::(.type);
	if !$proj && $proj ~~ Failure {
		require ::(.type);
		$proj = ::(.type);
	}

	$proj.HOW.manager = self;
	my @ids = $proj.^aggregation-ids-attrs.map: *.name.substr: 2;
	%!instances{$proj.^name}<class> = $proj;
	for $proj.^applyable-events -> $event {
		%!events.push: $event.^name => $proj
	}
}

proto method create-object($type, *%data) {*}

multi method create-object(Mu:U $type, *%data) {
	$.create-object: $type.^name, |%data
}

multi method create-object(Str $type, *%data) is command {
	self._create-object($type, |%data)
}

multi method _create-object(Str $type, *%data) {
	my :(Sourcing::Projection :$class!, :%instances) := %!instances{$type};
	my @agg = $class.^aggregation-ids-names;
	my @arg = $class.^projection-arg-names;

	my @path = |%data{|@agg, |@arg};
	die "Object ($type: %data.raku()) already exists" with %instances{||@path};

	$.projection-object-created: :$type, :%data;
}

multi method apply(ProjectionObjectCreated $_) {
	#say "apply: ", $?LINE, " - ", $_;
	my :(:$class, :%instances) := %!instances{.type};

	my @agg = $class.^aggregation-ids-names;
	my @arg = $class.^projection-arg-names;

	my @path = |.data{|@agg, |@arg};

	my $instance = %instances{||@path} = $class.new: |.data;
	%!instances{.type}<instances> = %instances;
	$instance._receive-events;
	$instance
}

multi method apply(Sourcing::Event $event) {
	my $seq = $*SOURCING-MESSAGE-SEQ;
	my @classes = gather for |$event.^mro, |$event.^roles -> $parent {
		for |%!events{ $parent.^name } {
			.take with %!instances{ .^name }
		}
	}
	die "Unexpected event $event.raku() (@classes[])" unless @classes;
	for @classes <-> %item (:$class!, :%instances, |) {
		my @agg = $class.^aggregation-ids-from-event: $event;
		my %agg is Map = $class.^aggregation-ids-map-from-event: $event;
		my @arg = $class.^projection-arg-from-event: $event;
		my %arg is Map = $class.^projection-arg-map-from-event: $event;
		my @path = |@agg, |@arg;
		with %instances{||@path} {
			._receive-event: :$seq, $event;
		} else {
			$._create-object: $class.^name, |%agg, |%arg
		}
	}
}
