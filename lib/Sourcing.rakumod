no precompilation;
unit class Sourcing;

has Mu:U     %.command-classes;
has          &.command-emitter;
has Mu       $.command-handler = Metamodel::ClassHOW.new_type: :name<Sourcing::CommandHandler>;

has Mu:U     %.event-classes;
has          &.event-emitter;
has Mu       $.event-handler = Metamodel::ClassHOW.new_type: :name<Sourcing::EventHandler>;

method instance { $ //= ::?CLASS.bless }
method new(|) {!!!}

method set-command-emitter(&emitter) {
	&!command-emitter = &emitter
}

multi method set-event-emitter(&emitter) {
	&!event-emitter = &emitter
}

method get-command-handler {
	$!command-handler.^compose;
	$!command-handler
}

method get-event-handler {
	$!event-handler.^compose;
	$!event-handler
}

multi trait_mod:<is>(Routine $r, :$sourcing-command) is export {
	my $class = Sourcing.instance.add-command: $r;
	$r.wrap: sub (|c) {
		$class.new: |c
	}
}

multi trait_mod:<is>(Routine $r, :$sourcing-event) is export {
	my $class = Sourcing.instance.add-event: $r;
	$r.wrap: sub (|c) {
		$class.new: |c
	}
}

role FromSignature[Str $emitter] {
	method to-map(--> Map()) {
		self.^attributes.map: {
			.name.substr(2) => .get_value: self
		}
	}
	method TWEAK(|) {
		.(self) with Sourcing.instance."$emitter"()
	}
}

role Command does FromSignature["command-emitter"] {}
role Event does FromSignature["event-emitter"] {}

method add-command(&cmd) {
	die "Functions can't have positional params to be transformed into a command, {&cmd.name} do not respect that"
		if &cmd.count;
	my $name = "{ &cmd.name.tc.subst: /\W(\w)/, { $0.uc }, :g }Command";
	my &cloned = &cmd.clone;
	%!command-classes{$name} = my $class = self!class-from-signature($name, &cmd.signature, :roles[Command]);
	$!command-handler.^add_multi_method: "handle", my method handle(Any: $cmd where $class) {
		cloned |$cmd.to-map
	}
	$class
}

method add-event(&ev) {
	die "Functions can't have positional params to be transformed into a event, {&ev.name} do not respect that"
		if &ev.count;
	my $name = "{ &ev.name.tc.subst: /\W(\w)/, { $0.uc }, :g }Event";
	my &cloned = &ev.clone;
	%!event-classes{$name} = my $class = self!class-from-signature($name, &ev.signature, :roles[Event]);
	$!event-handler.^add_multi_method: "handle", my method handle(Any: $ev where $class) {
		cloned |$ev.to-map
	}
}

method !class-from-signature(Str $class-name, Signature $sig, :@roles) {
	my $class = Metamodel::ClassHOW.new_type: :name($class-name);
	$class.^add_role: $_ for @roles;
	for $sig.params.grep(*.named) -> $param {
		my Str $par-name = .named_names.head // .name with $param;
		my Str $attr-name = $param.name.subst: /^(<[$@%&]>)(\w+)$/, { "$0!$1" };
		my $attr = Attribute.new:
			:name($attr-name),
			:1ro,
			:1has_accessor,
			:type($param.type),
			:package($class),
		;
		$class.^add_attribute: $attr;
		use nqp;
		nqp::bindattr(
			$attr<>,
			Attribute,
			'$!required',
			1,
		) if not $param.optional;
	}
	$class.^compose;
	$class
}

=begin pod

=head1 NAME

Sourcing - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use Sourcing;

=end code

=head1 DESCRIPTION

Sourcing is ...

=head1 AUTHOR

Fernando Corrêa de Oliveira <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
