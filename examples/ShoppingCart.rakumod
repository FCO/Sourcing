use Sourcing;
use ShoppingCartCreated;
use ShoppingCartItemAdded;

unit projection ShoppingCart is aggregated-by<user>;

has UInt $.user;
has UInt @.items;
has Bool $.done = False;

method created(ShoppingCartCreated $_) {
	$!user = .user;
}

method item-added(ShoppingCartItemAdded $_) {
	@!items.push: .item
}
