unit class Metamodel::ProjectionHOW is Metamodel::ClassHOW;

has %.meths;

sub to-map($obj --> Map()) {
	$obj.^attributes.map: {
		.name.substr(2) => .get_value: $obj
	}
}

method add_method(Mu $projection, $name, &meth, |c) {
	nextsame if self.is_composed($projection);
	nextsame if $name eq uc $name;
	my @attrs = $projection.^attributes>>.name>>.substr: 2;
	nextsame if @attrs.first: { $_ eq $name };

	my $class-name = S:g/"-"(\w)/{$0.uc}/ with $name.tc;
	try require ::($class-name);
	my $class = ::($class-name);
	if $class ~~ Failure {
		note "$class-name class not found";
		nextsame
	}
	%!meths.push: $class-name => &meth;
	self.add_multi_method($projection, "apply", my method (::($class-name) $ev) {
		meth self, |$ev.&to-map
	});
}
