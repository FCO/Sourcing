use Sourcing::AggregationId;
use Sourcing::ProjectionArg;
use Sourcing::Projection;
use Sourcing::Utils;

multi trait_mod:<is>(Attribute $r, Bool :$aggregation-id!) is export {
	#trait_mod:<is>($r, :required);
	$r does Sourcing::AggregationId
}

multi trait_mod:<is>(Attribute $r, Bool :$projection-arg!) is export {
	$r does Sourcing::ProjectionArg
}

multi trait_mod:<is>(Routine $r, Bool :$query!) is export {
	querify $r;
}

multi trait_mod:<is>(Routine $r, Bool :$command!) is export {
	commandify $r;
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
