use Sourcing;
use UUID::V4;
use Account;
use TransferTransactionCreated;

unit process TransferTransaction;

has Str     $.id is aggregation-id = uuid-v4;
has Account $.from;
has Account $.to;
has Rat     $.amount;
has Bool    $.done = False;

multi method create-transfer(::?CLASS:U: Str $from, Str $to, Rat $amount) {
	my $transfer = ::?CLASS.new;
	$transfer.create-transfer: $from, $to, $amount;
	$transfer
}

multi method create-transfer(::?CLASS:D: Str $from, Str $to, Rat $amount) is command {
	$.transfer-transaction-created: :$from, :$to, :$amount;
}

multi method apply(TransferTransactionCreated $_) {
	$!id     = .id;
	$!from   = Account.new: :id(.from);
	$!to     = Account.new: :id(.to);
	$!amount = .amount;

	say "Transfering $!amount from $!from.id() to $!to.id()";

	$!from.withdraw: $!amount;
	$.on-error: { $!from.deposit: $!amount }
	$!to.deposit: $!amount;
}
