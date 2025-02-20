use Sourcing::EventStore::Red;
use Aggregation::Account;
use Projection::AccountTotalReceived;
use Projection::AccountTotalSent;
use Process::TransferTransaction;
use Projection::Statement;
use Sourcing::Manager;
use UUID::V4;

#my $*RED-DEBUG = True;
#use Sourcing::EventStore::Red;
#my $*EVENT-STORE = Sourcing::EventStore::Red.new: :pars{ :database<a.db> }

my $manager = Sourcing::Manager.new: :transaction-id(Str);

$manager.register-class: Aggregation::Account;
$manager.register-class: Projection::AccountTotalReceived;
$manager.register-class: Projection::AccountTotalSent;
$manager.register-class: Projection::Statement;
$manager.register-class: Process::TransferTransaction;

my Aggregation::Account $acc1 .= create-account: 1000.0;
my Aggregation::Account $acc2 .= create-account: 1000.0;

for ^10 {
	my ($sender, $receiver) = ($acc1, $acc2).pick: *;
	my Process::TransferTransaction $transaction .= create-transfer: $sender.id, $receiver.id, ^100 .pick.Rat;
}

say "processing events..." while $manager.receive-events;

say $manager.get: Aggregation::Account, :id($acc1.id);
say $manager.get: Aggregation::Account, :id($acc2.id);

say $manager.get: Projection::AccountTotalSent, :id($acc1.id);
say $manager.get: Projection::AccountTotalReceived, :id($acc1.id);
say $manager.get: Projection::AccountTotalSent, :id($acc2.id);
say $manager.get: Projection::AccountTotalReceived, :id($acc2.id);

say "\nStatement { $acc1.id }: ";
say $manager.get(Projection::Statement, :id($acc1.id)).statement;

say "\nStatement { $acc2.id }: ";
say $manager.get(Projection::Statement, :id($acc2.id)).statement;
