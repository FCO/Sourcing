use Sourcing::EventStore::Red;
use ShoppingCartAgg;
use Sourcing::Manager;

my $*RED-DEBUG = True;

my $manager = Sourcing::Manager.new;
$manager.register-class: ShoppingCartAgg;

for [1,2,3] -> $user {
	my $cart = ShoppingCartAgg.create-shopping-cart: $user;
	$cart.add-item: ++$
}

for [3,2,1] -> $user {
	my $cart = ShoppingCartAgg.new: :$user;
	$cart.add-item: $user + 10;
	$cart.finish
}

say ShoppingCartAgg.new: :user($_) for 1, 2, 3
