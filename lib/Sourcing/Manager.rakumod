use v6.e.PREVIEW;
use Sourcing;
use Sourcing::Utils;
use Sourcing::Manager::ProjectionObjectCreated;
use Sourcing::Manager::ProjectionRegistred;
unit process Sourcing::Manager;

use Sourcing::Event;
use Sourcing::Projection;
use Sourcing::EventStore;

has %.events;
has %.instances = self.^name => %(class => self.WHAT, instances => %(Str => self));

has Lock::Async $!manager-lock .= new;

method get-instance(Str $type, %ids) is query{ :sync } {
	my :(:%instances, :$class) := %!instances{$type};
	my @names = |$class.^aggregation-ids-names, |$class.^projection-arg-names;
	my @ids := %ids{@names};
	%instances{||@ids} //= self.create-object: $type, |%ids
}

multi method register-class(Mu:U $type) {
	$.register-class: $type.^name
}

multi method register-class(Str $type) is command {
	#die "Class $type already registred" with %!instances{$type}; 
	return True with %!instances{$type}; 
	$.projection-registred: :$type;
	True
}

method describe-class(Str $type) is query{ :sync } {
	given %!instances{$type}<class> {
		return %(
			projection-arg  => .^projection-arg-attrs.map({ %( :name(.name), :type(.type) ) }).List,
			aggregation-ids => .^aggregation-ids-attrs.map({ %( :name(.name), :type(.type) ) }).List,
			queries         => .^methods>>.candidates.flat.grep(*.?is-query).map(-> &meth {
				&meth.name => &meth.signature.params.skip.head(*-1)>>.raku.List
			}).List,
			commands        => .^methods>>.candidates.flat.grep(*.?is-command).map(-> &meth {
				&meth.name => &meth.signature.params.skip.head(*-1)>>.raku.List
			}).List,
		)
	}
}

multi method apply(Sourcing::Manager::ProjectionRegistred $_) {
	my $type = .type;
	try my $proj = ::($type);
	if !$proj && $proj ~~ Failure || $proj === Any {
		require ::($type);
		$proj = ::($type);
	}

	$proj.throw if $proj ~~ Failure;
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
	#die "Object ($type: %data.raku()) already exists" with %instances{||@path};

	$.projection-object-created(:$type, :%data);
}

multi method apply(Sourcing::Manager::ProjectionObjectCreated $_) {
	my :(:$class, :%instances) := %!instances{.type};

	my @agg = $class.^aggregation-ids-names;
	my @arg = $class.^projection-arg-names;

	my @path = |.data{|@agg, |@arg};

	my $instance = %instances{||@path} = $class.new: |.data;
	%!instances{.type}<instances> = %instances;
	$instance._receive-events;
	$instance
}

proto method _unload-object(| --> Bool()) {*}
multi method _unload-object(%instances, []) {}
multi method _unload-object(%instances, [$key]) { %instances{$key}:delete }
multi method _unload-object(%instances, [$key, *@rest]) {
	do if so $._unload-object: %instances{$key}, @rest {
		%instances{$key}:delete unless %.instances{$key}
	}
}

method unload-object(Str $type, *%data) is command {
	my :(Sourcing::Projection :$class!, :%instances) := %!instances{$type};
	my @agg = $class.^aggregation-ids-names;
	my @arg = $class.^projection-arg-names;

	my @path = |%data{|@agg, |@arg};

	event-store.add-event: %instances{||@path};
}

multi method apply(Sourcing::Projection $projection) {
	$._unload-object:
		%!instances{$projection.^name},
		[
			|$projection.^aggregation-ids-values,
			|$projection.^projection-arg-values,
		]
	;
}

multi method apply(Sourcing::Event $event) {
	my $seq = $*SOURCING-MESSAGE-SEQ;
	my @classes = gather for |$event.^mro, |$event.^roles -> $parent {
		for |%!events{ $parent.^name } {
			.take with %!instances{ .^name }
		}
	}
	#die "Unexpected event $event.raku() (@classes[])" unless @classes;
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
