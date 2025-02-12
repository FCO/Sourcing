sub event-store is export {
	require Sourcing::EventStore::Red;
	$*EVENT-STORE // $GLOBAL::EVENT-STORE //= Sourcing::EventStore::Red.new
}

sub lockify(Routine $r) is export {
	$r.wrap: my method (\SELF: |c) {
		my &run-method = nextcallee;
		return run-method SELF, |c without self;
		my $lock = self.^attributes.first(*.name eq '$!lock').get_value(self);
		$lock.protect: {
			run-method SELF, |c;
		}
	}
	$r
}

sub querify(Routine $r) is export {
	$r does role {
		method is-query { True }
	}
	lockify $r
}

sub commandify(Routine $r) is export {
	my &clone = $r.clone;
	$r does role {
		method is-command { True }
	}
		
	$r.wrap: my method (|c) {
		self._receive-events;
		clone self, |c
	}
	lockify $r
}

#| Accepts a string and converts snake case (`foo_bar`) into kebab case (`foo-bar`).
sub snake-to-kebab-case(Str() $_ --> Str) is export { S:g/'_'/-/ }
#| Accepts a string and converts kebab case (`foo-bar`) into snake case (`foo_bar`).
sub kebab-to-snake-case(Str() $_ --> Str) is export { S:g/'-'/_/ }
#| Accepts a string and converts camel case (`fooBar`) into snake case (`foo_bar`).
sub camel-to-snake-case(Str() $_ --> Str) is export { kebab-to-snake-case lc S:g/(\w)<?before <[A..Z]>>/$0_/ }
#| Accepts a string and converts camel case (`fooBar`) into kebab case (`foo-bar`).
sub camel-to-kebab-case(Str() $_ --> Str) is export { lc S:g/(\w)<?before <[A..Z]>>/$0-/ }
#| Accepts a string and converts kebab case (`foo-bar`) into camel case (`fooBar`).
sub kebab-to-camel-case(Str() $_ --> Str) is export { S:g/"-"(\w)/{$0.uc}/ with .wordcase }
#| Accepts a string and converts snake case (`foo_bar`) into camel case (`fooBar`).
sub snake-to-camel-case(Str() $_ --> Str) is export { S:g/"_"(\w)/{$0.uc}/ with .wordcase }
