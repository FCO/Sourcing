unit role Sourcing::EventStore;
use Sourcing::Event;
use Sourcing::Projection;

method add-event(Sourcing::Event) { ... }
method get-events($index?)        { ... }

method attach-projection(Sourcing::Projection:D $proj, Bool :$from-beginnig = False) {
	$proj.^receive-unfiltered-events: $.get-events(:$from-beginnig)
}
