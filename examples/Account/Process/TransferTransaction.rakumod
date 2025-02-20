use Sourcing;
use Aggregation::Account;
use Event::Withdrew;
use Event::Deposited;
use Event::TransferTransactionCreated;

unit process Process::TransferTransaction;

has Aggregation::Account $.from;
has Aggregation::Account $.to;
has Rat                  $.amount;
has Bool                 $.done = False;

multi method create-transfer(::?CLASS:U: Str $from, Str $to, Rat $amount) {
	my $transfer = ::?CLASS.new;
	$transfer.create-transfer: $from, $to, $amount;
	$transfer
}

multi method create-transfer(::?CLASS:D: Str $from, Str $to, Rat $amount) is command {
	die "The sending acount and the receiving account are the same account" if $from eq $to;
	$.transfer-transaction-created: :$from, :$to, :$amount;
}

multi method apply(Event::TransferTransactionCreated $_) {
	$!transaction-id = .transaction-id;
	$!from           = Aggregation::Account.new: :id(.from);
	$!to             = Aggregation::Account.new: :id(.to);
	$!amount         = .amount;

	die "You cannot create a transaction to and from the same account" if $!from eq $!to;

	$!from.withdraw: $!amount, $!to.id, :transaction(self);
	# $.wait-for: 5;
}

multi method apply(Event::Withdrew $_) {
	$.on-error: { $!from.refund: $!amount, self }
	$!to.deposit: $!amount, $!from.id, :transaction(self);
	# $.wait-for: 5; # NYI
}
