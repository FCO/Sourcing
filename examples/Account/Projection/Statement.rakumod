use Sourcing;
use UUID::V4;
use Event::AccountCreated;
use Event::Deposited;
use Event::Withdrew;
use Event::Refund;

unit projection Projection::Statement;

has Str $.id is required is aggregation-id;
has     @.transactions;

method statement is query {
	join "\n", $!id, @!transactions
}

multi method apply(Event::AccountCreated $_) {
	$!id = .id;
	@!transactions.push: "{ .timestamp }: Account was created with { .initial }"
}

multi method apply(Event::Deposited $_) {
	die "error!!! $!id ne { .id }" unless $!id eq .id;
	die "{ .^name } the sender and the destination are the same account" if $!id eq .from;
	@!transactions.push: "{ .timestamp }: { .amount } received from { .from }"
}

multi method apply(Event::Refund $_) {
	die "error!!! $!id ne { .id }" unless $!id eq .id;
	@!transactions.push: "{ .timestamp }: { .amount } refunded bacause of error on transaction { .failed-transaction }"
}

multi method apply(Event::Withdrew $_) {
	die "error!!! $!id ne { .id }" unless $!id eq .id;
	die "{ .^name } the sender and the destination are the same account" if $!id eq .to;
	@!transactions.push: "{ .timestamp }: { .amount } sent to { .to }"
}
