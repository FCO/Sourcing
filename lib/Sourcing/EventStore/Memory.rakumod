use Sourcing::EventStore;
unit class Sourcing::EventStore::Memory does Sourcing::EventStore;

has Supplier $.supplier .= new;
has Supply() $.supply    = $!supplier;
has          @.data;

method TWEAK(|) {
	$!supply.tap: { @!data.push: $_ }
}

method add-event(Sourcing::Event $event) {
	$!supplier.emit: $event
}

multi method get-events(Bool :$from-beginnig where *.so --> Supply) {
	Supply.merge: Supply.from-list(@!data), $!supply
}

multi method get-events(Bool :$from-beginnig! where *.not --> Supply) {
	$!supply
}
