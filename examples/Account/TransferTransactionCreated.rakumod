use Sourcing;
unit event TransferTransactionCreated;

has Str $.id      is required;
has Str $.from    is required;
has Str $.to      is required;
has Rat $.amount  is required;
