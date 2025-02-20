use Sourcing;
use ShoppingCartCreated;
use ShoppingCartItemAdded;
use ShoppingCartDone;

unit aggregation ShoppingCartAgg;

has UInt     $.user is aggregation-id;
has DateTime $.created-at;
has UInt     @.items;
has Bool     $.done = False;

multi method create-shopping-cart(::?CLASS:U: $user) {
	my $new = $.new(:$user);
	$new.create-shopping-cart;
	$new
}

multi method create-shopping-cart(::?CLASS:D:) is command {
	die "Shopping cart for user $!user already created" if $!created-at;
	$.shopping-cart-created;
}

multi method apply(ShoppingCartCreated $_) {
	$!user = .user;
	$!created-at = .timestamp;
}

method add-item(UInt $item) is command {
	die "Shopping cart for user $!user not created" unless $!created-at;
	die "Shopping cart for user $!user already done" if $!done;
	$.shopping-cart-item-added: :$item
}

multi method apply(ShoppingCartItemAdded $_) {
	@!items.push: .item
}

method finish is command {
	die "Shopping cart for user $!user not created" unless $!created-at;
	die "Shopping cart for user $!user already done" if $!done;
	$.shopping-cart-done
}

multi method apply(ShoppingCartDone $_) {
	$!done = True
}

method get-items is query {
	@!items.join: ", ";
}
