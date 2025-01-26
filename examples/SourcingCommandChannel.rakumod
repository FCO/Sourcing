use Sourcing;

my Sourcing $sourcing .= instance;

my $prom = start {
	my Channel $ch .= new;

	$sourcing.set-command-emitter: -> $obj { $ch.send: $obj }

	my $handler = $sourcing.get-command-handler.new;
	react whenever $ch -> $obj {
		$handler.handle: $obj;
	}
}

sub awaits-command-handler is export { await $prom }
