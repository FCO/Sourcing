no precompilation;
my %types;

role Sourcing { ... }

role Sourcing::AutoEmit[Str $type] {
	method TWEAK(|) {
		.(self) with Sourcing[$type].instance.emitter
	}
}

my role Sourcing[Str $type = "command"] {
	has %.funcs;
	has %.commands;
	has &.handler is rw;
	has &.emitter is rw;

	multi method instance { %types{$type} //= ::?CLASS.bless }

	multi method handle(::?CLASS:D: Sourcing::AutoEmit $cmd) {
		$.handler.($cmd)
	}

	method new {!!!}

	method emitter-sub is rw {
		self.instance.emitter
	}

	method get-ns(@ns) is raw {
		my $ptr = %!funcs;
		for @ns -> Str $path {
			last without $ptr{$path};
			$ptr = $ptr{$path};
		}
		$ptr
	}

	sub visitor(%node) {
		for %node.kv -> Str $key, $_ {
			when Callable    { take ($key => $_)                     }
			when Associative { .&visitor                             }
			default          { die "unexpected value for { .^name }" }
		}
	}

	method get-funcs(@ns) {
		my $ptr = $.get-ns: @ns;
		gather { visitor $ptr }
	}

	method add-function(
		&func where {
			.count == 0
			|| fail "Only functions with no positional parameters can be commands"
		},
		Str :$name = &func.name,
		:@ns
	) {
		my %funcs := $.get-ns: @ns;
		%funcs{$name} = &func;
	}
}

my \Command = Sourcing["command"];
my \Event   = Sourcing["event"];

multi trait_mod:<is>(Routine $cmd, :$sourcing-command!) is export {
	my $instance = Command.instance;
	$instance.add-function: $cmd;
}

multi trait_mod:<is>(Routine $cmd, :$sourcing-event!) is export {
	my $instance = Event.instance;
	$instance.add-function: $cmd;
}

multi EXPORT("no-commands" --> Map()) {
	'Command' => Command.^pun,
	'Event'   => Event.^pun,
}

multi EXPORT(*@types --> Map()) {
	@types ||= <command event>;

	'Command' => Command.^pun,
	'Event'   => Event.^pun,

	'&EXPORT' => sub (@nss = ("",) --> Map()) {
		|@types.map: -> $type {
			my $handler = Metamodel::ClassHOW.new_type: :name<Sourcing::Handler>;
			my $instance = Sourcing[$type].instance;
			my %cmds = $instance.commands;

			|@nss.map: -> $ns {
				|Sourcing[$type].instance.get-funcs([ $ns.join("::").split: "::" ]).map: -> (:$key, :$value) {
					"&$key" => sub (*%named) {
						%cmds{$key} //= do {
							my $cmd-name = "{ $key.tc.subst: /\W(\w)/, { $0.uc }, :g }{ tc "Command" }";
							my $cmd = Metamodel::ClassHOW.new_type: :name($cmd-name);
							$cmd.^add_role: Sourcing::AutoEmit["command"];
							for $value.signature.params.grep(*.named) -> $param {
								my Str $par-name = .named_names.head // .name with $param;
								my Str $attr-name = $param.name.subst: /^(<[$@%&]>)(\w+)$/, { "$0!$1" };
								my $attr = Attribute.new:
									:name($attr-name),
									:1ro,
									:1has_accessor,
									:type($param.type),
									:package($cmd),
								;
								$cmd.^add_attribute: $attr;
								use nqp;
								nqp::bindattr(
									$attr<>,
									Attribute,
									'$!required',
									1,
								) if not $param.optional;
							}
							$cmd.^add_method: 'to-map', my method (--> Map()) {
								self.^attributes.map: {
									.name.substr(2) => .get_value: self
								}
							}
							$cmd.^compose;
							$cmd
						}
						$handler.^add_multi_method: "CALL-ME", my method ($command where { $_ ~~ %cmds{$key} }) {
							$value.(|$command.to-map)
						}
						$handler.^add_role: Callable;
						$handler.^compose;
						$instance.handler = $handler;
						%cmds{$key}.new: |%named
					}
				}
			}
		}
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
