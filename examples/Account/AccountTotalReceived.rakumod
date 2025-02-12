use Sourcing;
use UUID::V4;
use AccountCreated;
use Deposited;

unit projection AccountTotalReceived;

has Str      $.id is aggregation-id;
has Rat      $.received = 0.0;

multi method apply(AccountCreated $_) {
	$!id       = .id;
	$!received = .initial;
}

multi method apply(Deposited $_) {
	$!received += .amount
}
