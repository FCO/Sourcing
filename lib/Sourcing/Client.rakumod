unit class Sourcing::Client;
use JSON::Fast;

use Nats;

has Nats $.nats .= new;
has      %.clients;

method TWEAK(|) { await $!nats.start }

method register-class(Str $class) {
	my \answer = (await $!nats.request: "register_class", $class).json;
	die answer<error> if answer ~~ Associative && answer<error>;
	answer
}

method get-class-client(Str $class) {
	%!clients{$class} //= do {
		my :(
			:@aggregation-ids,
			:@projection-arg,
			:@queries,
			:@commands,
			:$error,
			:$error-type,
		) := (await $!nats.request: "describe_class", $class).json;

		die $error if $error;

		my \type = Metamodel::ClassHOW.new_type: :name($class);

		for |@aggregation-ids, |@projection-arg -> %attr (:$name, :$type) {
			type.^add_attribute: Attribute.new: :$name, :$type, :has_accessor, :package(type)
		}
		my $nats = $!nats;

		type.^add_method: "new", my method new(Any: *%ids) {
			my $self = self.bless: |%ids;
			my \answer = (await $nats.request: "create_object", %(:type($class), :%ids).&to-json).json;
			die answer<error> if answer ~~ Associative && answer<error>;
			$self
		}

		type.^add_method: "prepare-data", my method prepare-data(Any: --> Map()) {
			do for |@aggregation-ids, |@projection-arg -> %attr (:$name, :$type) {
				$name.substr(2) => self.^attributes.first(*.name eq $name).get_value: self
			}
		}

		for @commands.map: *.pairs.head -> (:key($name), :value(@signature)) {
			my $code = (
				"my method { $name }(Any: |c ({ @signature.join: ", " })) "
				~ '{ my \answer = (await $nats.request: "command", %('
					~ " class => '$class',"
					~ " method => '$name',"
					~ ' ids => $.prepare-data,'
					~ ' list => c.list,'
					~ ' hash => c.hash,'
				~ ').&to-json).json;'
				~ ' die answer<error>'
					~ ' if answer ~~ Associative && answer<error>;'
				~ ' return answer'
				~ ' }'
			);
			type.^add_multi_method: $name, $code.EVAL;
		}

		for @queries.map: *.pairs.head -> (:key($name), :value(@signature)) {
			my $code = (
				"my method { $name }(Any: |c ({ @signature.join: ", " })) "
				~ '{ my \answer = (await $nats.request: "query", %('
					~ " class => '$class',"
					~ " method => '$name',"
					~ ' ids => $.prepare-data,'
					~ ' list => c.list,'
					~ ' hash => c.hash,'
				~ ').&to-json).json;'
				~ ' die answer<error>'
					~ ' if answer ~~ Associative && answer<error>;'
				~ ' return answer'
				~ ' }'
			);
			type.^add_multi_method: $name, $code.EVAL;
		}

		type.^compose;
		type
	}
}
