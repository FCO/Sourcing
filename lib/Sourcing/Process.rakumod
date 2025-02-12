use Sourcing::Aggregation;
use Sourcing::Utils;
unit role Sourcing::Process does Sourcing::Aggregation;

my enum ProcessStatus <Running Success Failed>;
has ProcessStatus $!status = Running;
has Callable      @!on-error;
has               $.error;

method on-error(&block) {
	@!on-error.push: &block
}

multi trait_mod:<is>(Routine $r, :$command!) { commandify $r }

method fail($error) is command {
	$!error = $error;
}
