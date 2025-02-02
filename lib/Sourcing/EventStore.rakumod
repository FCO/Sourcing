unit role Sourcing::EventStore;
use Sourcing::Event;
use Sourcing::Projection;

method add-event(Sourcing::Event)                  { ... }
method get-events(Bool :$from-beginnig --> Supply) { ... }

method attach-projection(Sourcing::Projection:D $proj, Bool :$from-beginnig = False) {
	$proj.^receive-unfiltered-events: $.get-events(:$from-beginnig)
}
