use Sourcing <
	ShoppingCartCreated
	ShoppingCartItemAdded
>;

sub create-shopping-cart(UInt :$user!) is sourcing-command is export {
	note "Creating shipping cart for user $user";
	shopping-cart-created :$user;
}

sub add-item(UInt :$item, UInt :$user!) is sourcing-command is export {
	note "Adding item $item to shopping cart from user $user";
	shopping-cart-item-added :$user, :$item;
}
