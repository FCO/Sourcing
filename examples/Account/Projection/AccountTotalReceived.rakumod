use Sourcing;
use UUID::V4;
use Event::AccountCreated;
use Event::Deposited;

unit projection Projection::AccountTotalReceived;

has Str      $.id is aggregation-id;
has Rat      $.received = 0.0;

multi method apply(Event::AccountCreated $_) {
	$!id       = .id;
	$!received = .initial;
}

multi method apply(Event::Deposited $_) {
	$!received += .amount
}
