use Metamodel::AggregationHOW;
use Sourcing::Process;

unit class Metamodel::ProcessHOW is Metamodel::AggregationHOW;

method compose(Mu $proj) {
	self.add_role: $proj, Sourcing::Process;
	callsame;
}
