no precompilation;
my %types;
class Sourcing::Command does Associative {
	has %.funcs;
	has %.commands;
	has &.handler is rw;
	has &.emitter is rw;

	role Event[Str $type where { "command" | "event" }] {
		method TWEAK(|) {
			.(self) with Sourcing::Command.instance($type).emitter
		}
	}

	method AT-KEY(Str $type)                     { $.instance: $type                }
	multi method instance(Str $type = "command") { %types{$type} //= ::?CLASS.bless }

	multi method handle(::?CLASS:D: Event $cmd) {
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

multi trait_mod:<is>(Routine $cmd, :$sourcing-command!) is export {
	my $instance = Sourcing::Command.instance<command>;
	$instance.add-function: $cmd;
}

multi trait_mod:<is>(Routine $cmd, :$sourcing-event!) is export {
	my $instance = Sourcing::Command.instance<event>;
	$instance.add-function: $cmd;
}

multi EXPORT("no-commands") {Map.new}
multi EXPORT(--> Map()) {
	my $handler = Metamodel::ClassHOW.new_type: :name<Sourcing::Command::Handler>;
	'&EXPORT' => sub (@nss = ("",) --> Map()) {
		my $instance = Sourcing::Command.instance<command>;
		my %cmds = $instance.commands;

		|@nss.map: -> $ns {
			|Sourcing::Command.instance<command>.get-funcs([ $ns.join("::").split: "::" ]).map: -> (:$key, :$value) {
				"&$key" => sub (*%named) {
					%cmds{$key} //= do {
						my $cmd-name = "{ $key.tc.subst: /\W(\w)/, { $0.uc }, :g }Command";
						my $cmd = Metamodel::ClassHOW.new_type: :name($cmd-name);
						$cmd.^add_role: Sourcing::Command::Event["command"];
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
