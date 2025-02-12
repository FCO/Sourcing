use Sourcing::EventStore::Red;
use ShoppingCartAgg;
use Sourcing::Manager;

my $manager = Sourcing::Manager.new;

$manager.register-class: ShoppingCartAgg;

my $*EVENT-STORE = Sourcing::EventStore::Red.new;
$manager.receive-events;

for [1,2,3] -> $user {
	my $cart = $manager.get: ShoppingCartAgg, :$user;
	$cart.create-shopping-cart: $user;
	$cart.add-item: ++$
}

for [3,2,1] -> $user {
	my $cart = $manager.get: ShoppingCartAgg, :$user;
	$cart.add-item: $user + 10;
	$cart.finish
}

say ShoppingCartAgg.new: :user($_) for 1, 2, 3
