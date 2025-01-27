use Sourcing;
use EventStore;

Sourcing.instance.set-event-emitter: -> $obj { EventStore.instance.add-event: $obj }
Sourcing.instance.set-query-emitter: -> $obj { EventStore.instance.query: $obj }
