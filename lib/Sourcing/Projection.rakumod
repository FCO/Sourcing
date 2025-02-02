use Sourcing::Event;
unit role Sourcing::Projection;

has Supply   $!event-store-supply;
has Supplier $!query-supplier .= new;
has Supply() $!query-supply    = $!query-supplier;
has Num      $!max-command-processed = -Inf;
