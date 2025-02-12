unit role Sourcing::Event;

has DateTime() $.timestamp      = now;
#has            $.command-id;
#has            $.causation-id   = $!command-id;
#has            $.correlation-id = $!causation-id;
