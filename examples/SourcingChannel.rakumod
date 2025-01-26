use Sourcing <no-commands>;

sub EXPORT(*@types --> Map()) {
	my %cmd-handler = @types.map: -> Str $type {
		$type => start {
			my Channel $ch .= new;

			Sourcing[$type].instance.emitter-sub = -> $cmd { $ch.send: $cmd }

			react whenever $ch -> $cmd {
				Sourcing[$type].instance.handle: $cmd;
				done
			}
		}
	}

	'&awaits-handlers' => sub () { await %cmd-handler.values },
	|%cmd-handler.kv.map: -> $key, $prom { "&awaits-{ $key }-handler" => sub { await $prom } },
}
