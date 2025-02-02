use Sourcing;
use Tuple;
use Sourcing::Event;
use Sourcing::Projection;
use Sourcing::EventStore;
unit projection Sourcing::Manager;

class ProjectionInfo {
	class Instance {
		has Supplier               $.query-supplier is required;
		has Sourcing::Projection:D $.instance       is required;

		multi method new(Sourcing::Projection $proj, *%agg-ids) {
			my $instance       = $proj.new: |%agg-ids;
			my $query-supplier = $instance.^query-supplier;

			$instance.HOW.event-store.attach-projection: $instance, :from-beginnig;

			::?CLASS.bless: :$query-supplier, :$instance
		}

		method gist { $!instance.gist }
	}

	has          $.projection;
	has          @.agg-ids is List;
	has Instance %.instance{Tuple};

	multi method new(Sourcing::Projection:U $proj) {
		::?CLASS.new:
			projection => $proj,
			agg-ids    => $proj.^aggregation-ids-attrs,
			events     => $proj.^applyable-events,
	}

	method gist {
		(
			$!projection.^name,
			"agg-ids: @!agg-ids[]",
			|(
				do for %!instance.kv -> @key, $instance {
					"{ @key.gist }\n{ $instance.gist.indent: 4 }"
				}.join("\n").indent: 4
			)
		).join: "\n"
	}
}

has Sourcing::EventStore $.event-store is required;
has ProjectionInfo       %.info{Sourcing::Projection:U};
has                      %.event{Sourcing::Event:U};

method TWEAK(:$event-store, |) {
	$event-store.attach-projection: self, :from-beginnig
}

method gist {
	(
		"info:",
		do for %!info.kv -> $proj, $info {
			"{ $proj.^name }\n{ $info.gist.indent: 4 }"
		}.join("\n").indent(4),
		"event:",
		do for %!event.kv -> $event, @info {
			"{ $event.^name }\n{ @info>>.gist.join("\n").indent: 4 }"
		}.join("\n").indent(4),
		"event-store: { $!event-store.gist }"
	).join: "\n"
}

multi method register-projection-class(::?CLASS $proj) {}

multi method register-projection-class(Sourcing::Projection $proj) {
	$proj.HOW.event-store = $.event-store;
	my $info = %!info{$proj.WHAT} = ProjectionInfo.new: $proj;
	for |$proj.^applyable-events -> Sourcing::Event $event {
		%!event{$event.WHAT}.push: $info;
	}
}

multi method apply(Sourcing::Event $event) {
	my @infos = %!event{$event.WHAT}<>;
	die "Unexpected event $event.raku()" unless @infos;
	for @infos -> $info {
		my @ids  = $info.projection.^aggregation-ids-from-event: $event;
		my %ids  = |($info.agg-ids.map(*.name.substr(2)) Z=> @ids);
		$info.instance{Tuple.new: @ids} //= ProjectionInfo::Instance.new: $info.projection, |%ids;
	}
}
