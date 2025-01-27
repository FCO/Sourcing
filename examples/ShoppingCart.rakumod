use Sourcing;

unit projection ShoppingCart;

has UInt $.user;
has UInt @.items;
has Bool $.done = False;

method shopping-cart-created(UInt :$user) {
	$!user = $user;
}

method shopping-cart-item-added(UInt :$user where { $_ eq $!user }, UInt :$item) {
	@!items.push: $item
}
