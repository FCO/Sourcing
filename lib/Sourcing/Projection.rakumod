unit role Sourcing::Projection;

has Int         $!last-processed = 0;
has Lock::Async $!lock .= new;
has DateTime    $!timestamp-to-kill;

method TWEAK(|) {
	$.receive-events
}

multi method apply(@events) { $.apply: $_ for @events }

method receive-events {
	$!lock.protect: { $._receive-events }
}

multi method _receive-events(::?CLASS:U:) {}

multi method _receive-events(::?CLASS:D:) {
	$!timestamp-to-kill = DateTime.now.later: :30minutes;
	my Capture $cap = \(
		$!last-processed // -1,
		:types($.^applyable-events.map: *.^name),
		|$.^aggregation-ids-map,
		|$.^projection-arg-map,
	);
	my UInt $*SOURCING-MESSAGE-SEQ;
	my @events = $*EVENT-STORE.get-events: |$cap;
	$.apply: @events;
	$!last-processed max= $*SOURCING-MESSAGE-SEQ;
}

method should-it-be-killed(DateTime $timestamp) {
	$!lock.protect: {
		my Bool $kill-it = $!timestamp-to-kill && $timestamp >= $!timestamp-to-kill;
		$.STORE-CACHE if $kill-it && $.^can: "STORE-CACHE";
		$kill-it
	}
}
