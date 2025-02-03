use ShoppingCart;
use ShoppingCartItemAdded;
use ShoppingCartCreated;
use ShoppingCartDone;
use Sourcing::Manager;

my $manager = Sourcing::Manager.new;
$manager.register-projection-class: ShoppingCart;

my @users = ^5;

race for @users.race(:8degree, :1batch) -> $user {
	$manager.event-store.add-event: ShoppingCartCreated.new: :$user;
	start {
		$manager.event-store.add-event: ShoppingCartItemAdded.new: :$user, :item($_)
	} for (1 .. 10).roll: (^10 + 1).pick;
	$manager.event-store.add-event: ShoppingCartDone.new: :$user;
}

say $manager;

my $sc = ShoppingCart.^client.new: :3user;
say $sc.items;
say $sc.get-items;
