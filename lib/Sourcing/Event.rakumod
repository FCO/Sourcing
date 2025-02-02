unit role Sourcing::Event;

has DateTime $.timestamp      = DateTime.now;
has          $.command-id;
has          $.causation-id   = $!command-id;
has          $.correlation-id = $!causation-id;
