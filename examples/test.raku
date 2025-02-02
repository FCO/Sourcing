use Sourcing::EventStore::Memory;
use ShoppingCart;
use ShoppingCartItemAdded;
use Sourcing::Manager;

my $event-store = Sourcing::EventStore::Memory.new;
my $manager     = Sourcing::Manager.new: :$event-store;

$manager.register-projection-class: ShoppingCart;

for [1, 42, 2, 42, 3, 42] -> $user {
	$event-store.add-event: ShoppingCartItemAdded.new: :$user, :item(++$)
}

say $manager;
