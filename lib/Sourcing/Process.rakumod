use Sourcing::Aggregation;
use Sourcing::Utils;
use Sourcing::AggregationId;
use Sourcing::Process::TimeoutWasSet;
use Sourcing::Process::Failed;
use UUID::V4;
unit role Sourcing::Process does Sourcing::Aggregation;

multi trait_mod:<is>(Routine $r, :$command!) { commandify $r }
multi trait_mod:<is>(Attribute $r, Bool :$aggregation-id!) is export {
	$r does Sourcing::AggregationId
}

my enum ProcessStatus <Running Success Failed>;
has Str           $.transaction-id is aggregation-id = uuid-v4;
has ProcessStatus $!status = Running;
has Callable      @!on-error;
has               $.error;
has Callable      %!timeouts{DateTime};

method on-error(&block) {
	@!on-error.push: &block
}

method set-timeout(%pairs (Pair :$key, |)) is command {
	for %pairs.kv -> (:key($unit), Num :$value), $method {
		$.timeout-was-set: ($unit => $value) => $method
	}
}

multi method apply(TimeoutWasSet $_) {
	#say "apply: Process:", $?LINE;
	%!timeouts{.timestamp.later: .unit => .value} = .method
}

method fail($error) is command {
	$.failed: :$error
}

multi method apply(Failed $_) {
	#say "apply: Process:", $?LINE;
	$!error = .error;
	for @!on-error -> &compensate {
		compensate
	}
}
