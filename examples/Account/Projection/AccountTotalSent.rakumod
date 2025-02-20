use Sourcing;
use UUID::V4;
use Event::AccountCreated;
use Event::Withdrew;
use Event::Refund;

unit projection Projection::AccountTotalSent;

has Str      $.id is aggregation-id;
has Rat      $.sent = 0.0;

multi method apply(Event::AccountCreated $_) {
	$!id = .id;
}

multi method apply(Event::Withdrew $_) {
	$!sent += .amount
}

multi method apply(Event::Refund $_) {
	$!sent -= .amount
}
