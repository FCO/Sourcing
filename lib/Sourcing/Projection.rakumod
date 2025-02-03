use Sourcing::Event;
unit role Sourcing::Projection;

has Supply   $!event-store-supply;
has Supplier $!query-supplier .= new;
has Supply() $!query-supply    = $!query-supplier;
has Num      $!max-command-processed = -Inf;
has          $!tap             = $!query-supply.tap: -> (:$vow, Str :$method, Capture :$capture) {
	CATCH {
		default {
			$vow.break: $_
		}
	}
	$vow.keep: self."{ $method }"(|$capture);
}
