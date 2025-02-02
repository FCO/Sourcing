unit class Metamodel::ProjectionHOW is Metamodel::ClassHOW;
use Sourcing::ProjectionClient;
use Sourcing::Projection;
use Sourcing::EventStore;

has                      $!client;
has Sourcing::EventStore $.event-store is rw;

method client(Mu $proj) {
	use Sourcing::ProjectionClient;
	return $!client if $!client ~~ Sourcing::ProjectionClient;
	$!client := Metamodel::ClassHOW.new_type: :name("{self.name: $proj}::Client");
	$!client.^add_role: Sourcing::ProjectionClient;
	given $!client {
		for $proj.^attributes -> $attr {
			my $attr-clone = Attribute.new:
				:name($attr.name),
				:1ro,
				:1has_accessor,
				:type($attr.type),
				:package($_),
			;
			use nqp;
			nqp::bindattr(
				$attr-clone<>,
				Attribute,
				'$!required',
				1,
			) if $attr.required;
			.^add_attribute: $attr-clone;
		}
		.^compose;
	}
	self.Metamodel::ClassHOW::compose: $proj;
}

method compose(Mu $proj) {
	self.add_role: $proj, Sourcing::Projection;
	nextsame;
}

method apply($proj, *@events) {
	use Sourcing::Event;
	do for @events -> Sourcing::Event $event {
		$proj.apply: $event
	}
}

method aggregation-ids-attrs($proj) {
	use Sourcing::AggregationId;
	$proj.^attributes.grep: Sourcing::AggregationId;
}

method aggregation-ids-values($proj --> List()) {
	do for $proj.aggregation-ids-attrs($proj) {
		.get_value: $proj
	}
}

method filter-event($proj, $event) {
	all do for $proj.^aggregation-ids-attrs {
		my $name = .name.substr: 2;
		.get_value($proj) eqv $event."$name"()
	}
}

method aggregation-ids-from-event($proj, Sourcing::Event $event --> List()) {
	$proj.^aggregation-ids-attrs.map: { $event."{ .name.substr: 2 }"() }
}

method applyable-events($proj --> List()) {
	do for self.find_method($proj, "apply").candidates -> &cand {
		my $type = &cand.signature.params.skip.head.type;
		next unless $type ~~ Sourcing::Event;
		next if $type<> === Sourcing::Event;
		$type
	}
}

method receive-unfiltered-events(Any:D $proj, Supply $supply) {
	$.receive-filtered-events: $proj, supply {
		whenever $supply -> $event {
			CATCH {default { .say }}
			next unless $proj.^filter-event: $event;
			emit $event
		}
	}
}

method receive-filtered-events(Any:D $proj, Supply $supply) {
	$supply.tap: -> $event {
		CATCH {default { .say }}
		$proj.^apply: $event
	}
}

method query-supplier($proj) {
	$proj.^attributes.first(*.name eq '$!query-supplier').get_value: $proj
}

multi method add_method(Mu $proj, Str, &meth where *.?is-command) {
	die "Projections don't have commands"
}

multi method add_method(Mu $proj, Str, &meth) {
	nextsame
}
