use OO::Actors;
unit class Metamodel::ProjectionHOW is Metamodel::ClassHOW;
use Sourcing::ProjectionClient;
use Sourcing::Projection;
use Sourcing::EventStore;
use Sourcing::Utils;

has                      $!client;
has Sourcing::EventStore $.event-store is rw;
has                      $.manager     is rw;

method compose(Mu $proj) {
	self.add_role: $proj, Sourcing::Projection;

	with $proj.^find_method("gist") {
		.&querify
	}

	nextsame;
}

method projection-arg-attrs($proj) {
	use Sourcing::ProjectionArg;
	$proj.^attributes.grep: Sourcing::ProjectionArg;
}

method aggregation-ids-attrs($proj) {
	use Sourcing::AggregationId;
	$proj.^attributes.grep: Sourcing::AggregationId;
}

method projection-arg-names($proj) {
	$proj.^projection-arg-attrs.map: *.name.substr: 2
}

method aggregation-ids-names($proj) {
	$proj.^aggregation-ids-attrs.map: *.name.substr: 2
}

method aggregation-ids-values($proj --> List()) {
	do for $proj.^aggregation-ids-attrs {
		.get_value: $proj
	}
}

method projection-arg-map($proj --> Map()) {
	do for $proj.^projection-arg-attrs {
		.name.substr(2) => .get_value: $proj
	}
}

method aggregation-ids-map($proj --> Map()) {
	do for $proj.^aggregation-ids-attrs {
		.name.substr(2) => .get_value: $proj
	}
}

method projection-arg-from-event($proj, Sourcing::Event $event --> List()) {
	$proj.^projection-arg-attrs.map: { $event."{ .name.substr: 2 }"() }
}

method aggregation-ids-from-event($proj, Sourcing::Event $event --> List()) {
	$proj.^aggregation-ids-attrs.map: { $event."{ .name.substr: 2 }"() }
}

method projection-arg-map-from-event($proj, Sourcing::Event $event --> Map()) {
	$proj.^projection-arg-attrs.map: { $event."{ .name.substr: 2 }"() }
	$proj.^projection-arg-names Z=> $proj.^projection-arg-attrs.map: { $event."{ .name.substr: 2 }"() }
}

method aggregation-ids-map-from-event($proj, Sourcing::Event $event --> Map()) {
	$proj.^aggregation-ids-names Z=> $proj.^aggregation-ids-attrs.map: { $event."{ .name.substr: 2 }"() }
}

method applyable-events($proj --> List()) {
	do for self.find_method($proj, "apply").candidates -> &cand {
		my $type = &cand.signature.params.skip.head.type;
		next unless $type ~~ Sourcing::Event;
		$type
	}
}

multi method add_method(Mu $proj, Str, &meth where *.?is-command) {
	die "Projections don't have commands"
}

multi method add_method(Mu $proj, Str, &meth) {
	nextsame
}
