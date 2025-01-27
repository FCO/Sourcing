use Sourcing;
use EventStore;

sub to-map($obj --> Map()) {
	$obj.^attributes.map: {
		.name.substr(2) => .get_value: $obj
	}
}

sub query($projection, *%data) is export {
	my $query-class = Metamodel::ClassHOW.new_type: :name("Query{ $projection.^name }");
	$query-class.^add_parent: $projection.WHAT;
	$query-class.HOW does role {
		method meths(|) { $projection.HOW.meths }
		method expects-event($query, $event) {
			so flat %.meths{$event.^name}.any.cando: \($query, |$event.&to-map)
		}
	}
	$query-class.^compose;
	my $query = $query-class.new: |$query-class.^attributes.map({ .name.substr(2) => Nil }).Map, |%data;
	EventStore.instance.query: $query;
}

Sourcing.instance.set-event-emitter: -> $obj { EventStore.instance.add-event: $obj }
