use Sourcing::EventStore::Red;
use Account;
use AccountTotalReceived;
use AccountTotalSent;
use TransferTransaction;
use Sourcing::Manager;
use UUID::V4;

#use Sourcing::EventStore::Red;
#my $*EVENT-STORE = Sourcing::EventStore::Red.new: :pars{ :database<a.db> }

my $manager = Sourcing::Manager.new;

$manager.register-class: Account;
$manager.register-class: AccountTotalReceived;
$manager.register-class: AccountTotalSent;
$manager.register-class: TransferTransaction;

my Account $acc1 .= create-account: 1000.0;
my Account $acc2 .= create-account: 1000.0;

my TransferTransaction $transaction .= create-transfer: $acc1.id, $acc2.id, 200.0;

say "processing events..." while $manager.receive-events;

say $manager.get: Account, :id($acc1.id);
say $manager.get: Account, :id($acc2.id);

say $manager.get: AccountTotalSent, :id($acc1.id);
say $manager.get: AccountTotalReceived, :id($acc1.id);
say $manager.get: AccountTotalSent, :id($acc2.id);
say $manager.get: AccountTotalReceived, :id($acc2.id);
