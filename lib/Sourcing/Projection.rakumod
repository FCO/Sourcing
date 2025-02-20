use Sourcing::Utils;
unit role Sourcing::Projection;

has Int         $!last-processed = 0;
has Lock::Async $!lock .= new;
has DateTime    $!timestamp-to-kill;

proto method apply($event) {
	my $seq = $*SOURCING-MESSAGE-SEQ;
	#say "initial({self.^name}) [[[ $*SOURCING-MESSAGE-SEQ ]]]((( $!last-processed )))";
	#say "($*SOURCING-MESSAGE-SEQ) => apply: ", $event;
	{
		my $*SOURCING-MESSAGE-SEQ = $seq;
		{*};
	}
	$!last-processed max= $*SOURCING-MESSAGE-SEQ;
	#say "final({self.^name}) [[[ $*SOURCING-MESSAGE-SEQ ]]]((( $!last-processed )))";
}

method receive-events {
	$!lock.protect: { $._receive-events }
}

multi method _receive-events(::?CLASS:D:) {
	#$!timestamp-to-kill = DateTime.now.later: :30minutes;
	my Capture $cap = \(
		$!last-processed // -1,
		:types($.^applyable-events.map: *.^name),
		|$.^aggregation-ids-map,
		|$.^projection-arg-map,
	);
	my UInt $*SOURCING-MESSAGE-SEQ;
	my @events = lazy  event-store.get-events: |$cap;
	for @events -> $event {
		#say "---> ", $event;
		$.apply: $event;
	}
}

multi method _receive-event($event, Int :$seq = $*SOURCING-MESSAGE-SEQ) {
	if $seq > $!last-processed {
		$.apply: $event;
		$!last-processed max= $seq
	}
}

method should-it-be-killed(DateTime $timestamp) {
	$!lock.protect: {
		my Bool() $kill-it = $!timestamp-to-kill && $timestamp >= $!timestamp-to-kill;
		$.STORE-CACHE if $kill-it && $.^can: "STORE-CACHE";
		$kill-it
	}
}
