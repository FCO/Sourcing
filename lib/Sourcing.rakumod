no precompilation;
class Sourcing {
	has Mu:U     %.command-classes;
	has          &.command-emitter;
	has Mu       $.command-handler = Metamodel::ClassHOW.new_type: :name<Sourcing::CommandHandler>;
	has          &.event-emitter;

	method instance { $ //= ::?CLASS.bless }
	method new(|) {!!!}

	method set-command-emitter(&emitter) {
		&!command-emitter = &emitter
	}

	method set-event-emitter(&emitter) {
		&!event-emitter = &emitter
	}

	method get-command-handler {
		$!command-handler.^compose;
		$!command-handler
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
}

multi trait_mod:<is>(Routine $r, :$sourcing-command) is export {
	my $class = Sourcing.instance.add-command: $r;
	$r.wrap: sub (|c) {
		$class.new: |c
	}
}

multi EXPORT(*@events --> Map()) {
	'&trait_mod:<is>' => &trait_mod:<is>,
	|@events.map: -> $event {
		my $func-name = lc S:g/(\w)<?before <[A..Z]>>/$0-/ given $event;
		require ::($event);
		"&$func-name" => sub (|c) {
			my $obj = ::($event).new: |c;
			.($obj) with Sourcing.instance.event-emitter;
			$obj
		}
	}
}

my package EXPORTHOW {
    package DECLARE {
	use Metamodel::ProjectionHOW;
        constant projection = Metamodel::ProjectionHOW;
    }
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
