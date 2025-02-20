use Sourcing::AggregationId;
use Sourcing::ProjectionArg;
use Sourcing::Projection;
use Sourcing::Utils;

# TODO: Add a way to use aggregation-id with different names on different applies
#
# multi method apply(MyEvent $_) is mapping-aggregation-ids{id-on-event => "id-on-projection"} {...}
# multi method apply(MyEvent $_) is mapping-projection-args{timestamp => <from-timestamp to-timestamp>} {...}

multi trait_mod:<is>(Attribute $r, Bool :$aggregation-id!) is export {
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
