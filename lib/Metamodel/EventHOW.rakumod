unit class Metamodel::EventHOW is Metamodel::ClassHOW;
use Sourcing::Event;

method compose(Mu $event) {
	self.add_role: $event, Sourcing::Event;
	nextsame
}
