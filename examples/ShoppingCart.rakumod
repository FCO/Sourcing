use Sourcing;
use ShoppingCartCreated;
use ShoppingCartItemAdded;
use ShoppingCartDone;

unit projection ShoppingCart;

has UInt     $.user is aggregation-id;
has DateTime $.created-at;
has UInt     @.items;
has Bool     $.done = False;

multi method apply(ShoppingCartCreated $_) {
	say "apply: ", $_;
	$!user = .user;
	$!created-at = .timestamp;
}

multi method apply(ShoppingCartItemAdded $_) {
	say "apply: ", $_;
	@!items.push: .item
}

multi method apply(ShoppingCartDone $_) {
	say "apply: ", $_;
	$!done = True
}

method get-items is query {
	@!items.join: ", ";
}
