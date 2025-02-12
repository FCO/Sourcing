use Sourcing;
use UUID::V4;
use AccountCreated;
use Withdrew;

unit projection AccountTotalSent;

has Str      $.id is aggregation-id;
has Rat      $.sent = 0.0;

multi method apply(AccountCreated $_) {
	$!id = .id;
}

multi method apply(Withdrew $_) {
	say "total sent: ", self;
	$!sent += .amount
}
