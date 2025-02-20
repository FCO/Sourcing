use Sourcing;
unit event Event::Withdrew;

has Str $.transaction-id is required;
has Str $.id             is required;
has     $.to             is required;
has Rat $.amount;
