use Sourcing::AggregationId;

multi trait_mod:<is>(Attribute $r, Bool :$aggregation-id!) is export {
	trait_mod:<is>($r, :required);
	$r does Sourcing::AggregationId
}

my package EXPORTHOW {
	package DECLARE {
		use Metamodel::ProjectionHOW;
		use Metamodel::AggregationHOW;
		use Metamodel::ProcessHOW;
		use Metamodel::EventHOW;

		constant projection  = Metamodel::ProjectionHOW;
		constant aggregation = Metamodel::AggregationHOW;
		constant process     = Metamodel::ProcessHOW;
		constant event       = Metamodel::EventHOW;
	}
}
