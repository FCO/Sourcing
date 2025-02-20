use Sourcing;
unit event Event::TransferTransactionCreated;

has Str $.transaction-id is required;
has Str $.from           is required;
has Str $.to             is required;
has Rat $.amount         is required;
