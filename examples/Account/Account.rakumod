use Sourcing;
use UUID::V4;
use AccountCreated;
use Deposited;
use Withdrew;

unit aggregation Account;

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

multi method apply(AccountCreated $_) {
	$!id      = .id;
	$!created = .timestamp;
	$!amount  = .initial;
}

method deposit(Rat $amount) is command {
	die "Can't deposit to an account not created" unless $!created;
	$.deposited: :$amount;
}

multi method apply(Deposited $_) {
	say "$!id receiving a deposit of { .amount }";
	$!amount += .amount
}

method withdraw(Rat $amount) is command {
	die "Can't withdraw to an account not created" unless $!created;
	die "No enough amount to withdraw $amount" if $amount > $!amount;
	$.withdrew: :$amount;
}

multi method apply(Withdrew $_) {
	say "$!id doing a withdraw of { .amount }";
	$!amount -= .amount
}
