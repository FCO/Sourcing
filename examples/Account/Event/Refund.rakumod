use Sourcing;
unit event Event::Refund;

has Str $.transaction-id is required;
has Str $.id             is required;
has Rat $.amount;
