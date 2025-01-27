unit class Metamodel::ProjectionHOW is Metamodel::ClassHOW;

has @.event-classes;

method compose(Mu $projection) {
	self.add_multi_method: $projection, "apply", my method ($ev) {
		note "could not apply ", $ev;
	}
	self.Metamodel::ClassHOW::add_method: $projection, "query", my method ($id) {
		CATCH { default { .say } }
		my Promise $p .= new;
		my $query = Map.new: (:projection(self.WHAT), :$id, :event-classes($.HOW.event-classes), :response($p.vow));
		require ::("Sourcing");
		.($query) with ::("Sourcing").instance.query-emitter;
		await $p
	}

	nextsame
}

method add_method(Mu $projection, $name, &meth, |c) {
	nextsame if self.is_composed($projection);
	nextsame if $name eq uc $name;
	my %attrs := set $projection.^attributes>>.name>>.substr: 2;
	nextsame if %attrs{ $name };

	my $class = &meth.signature.params.skip.head.type;
	@!event-classes.push: $class;

	self.add_multi_method: $projection, "apply", my method ($ev where $class) {
		CATCH { default { .say; .die }}
		note "applying ", $ev;
		meth self, $ev
	}
}
