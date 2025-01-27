use Sourcing <
	ShoppingCartCreated
	ShoppingCartItemAdded
>;

sub create-shopping-cart(UInt :$user!) is sourcing-command is export {
	say "Creating shipping cart for user $user";
	say shopping-cart-created :$user;
}

sub add-item(UInt :$item, UInt :$user!) is sourcing-command is export {
	say "Adding item $item to shopping cart from user $user";
	say shopping-cart-item-added :$user, :$item;
}
