use Sourcing;

unit event Sourcing::Manager::ProjectionObjectCreated;

has Str $.type is required;
has     %.data;
