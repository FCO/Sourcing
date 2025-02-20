use Sourcing;
unit event Event::Deposited;

has Str $.transaction-id is required;
has Str $.id             is required;
has     $.from           is required;
has Rat $.amount;
