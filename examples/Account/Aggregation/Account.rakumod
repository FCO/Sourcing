use Sourcing;
use UUID::V4;
use Event::AccountCreated;
use Event::Deposited;
use Event::Withdrew;
use Event::Refund;

unit aggregation Aggregation::Account;

has Str      $.id is aggregation-id = uuid-v4;
has DateTime $.created;
has Rat      $.amount = 0.0;

multi method create-account(::?CLASS:U: Rat $initial = 0.0) {
	my $account = ::?CLASS.new;
	$account.create-account: $initial;
	$account
}

multi method create-account(::?CLASS:D: Rat $initial = 0.0) is command {
	die "Account already exists" if $!created;
	$.account-created: :$initial;
}

multi method apply(Event::AccountCreated $_) {
	$!id      = .id;
	$!created = .timestamp;
	$!amount  = .initial;
}

method deposit(Rat $amount, $from, :$transaction) is command {
	die "Can't deposit to an account not created" unless $!created;
	die "Trying to withdraw from the same account its going to credit" if $!id eq $from;
	$.deposited: :$amount, :$from, :transaction-id($transaction.transaction-id);
}

multi method apply(Event::Deposited $_) {
	$!amount += .amount
}

method refund(Rat $amount, $transaction) is command {
	die "Can't deposit to an account not created" unless $!created;
	$.deposited: :$amount, :transaction($transaction.transaction-id);
}

multi method apply(Event::Refund $_) {
	$!amount += .amount
}

method withdraw(Rat $amount, $to, :$transaction) is command {
	die "Can't withdraw to an account not created" unless $!created;
	die "No enough amount to withdraw $amount" if $amount > $!amount;
	die "Trying to withdraw from the same account its going to credit" if $!id eq $to;
	$.withdrew: :$amount, :$to, :transaction-id($transaction.transaction-id);
}

multi method apply(Event::Withdrew $_) {
	$!amount -= .amount
}
