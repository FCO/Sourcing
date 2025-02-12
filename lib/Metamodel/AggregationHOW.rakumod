use Metamodel::ProjectionHOW;
use Sourcing::Aggregation;
use Sourcing::Event;
use Sourcing::Utils;

unit class Metamodel::AggregationHOW is Metamodel::ProjectionHOW;

method compose(Mu $proj) {
	self.add_role: $proj, Sourcing::Aggregation;
	callsame;
	for |$.applyable-events: $proj -> Sourcing::Event $event {
		my $name = camel-to-kebab-case $event.^shortname;
		next if $proj.^find_method: $name;
		$proj.^add_method: $name, my method (|c) {
			my %agg is Map = self.^aggregation-ids-map with self;
			my %arg is Map = self.^projection-arg-map  with self;

			my Sourcing::Event $ev = $event.new: |%agg, |%agg, |c;
			event-store.add-event: $ev
		}
	}
	nextsame;
}

multi method add_method(Mu $proj, Str $name, &meth where *.?is-command, |c) {
	self.Metamodel::ClassHOW::add_method: $proj, $name, &meth, |c
}

