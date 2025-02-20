use Metamodel::EventHOW;
my \TimeoutWasSet = Metamodel::EventHOW.new_type: :name<Sourcing::Process::TimeoutWasSet>;

TimeoutWasSet.^add_attribute: Attribute.new: :package(TimeoutWasSet), :has_accessor, :type(Str), :name<$!transaction-id>;
TimeoutWasSet.^add_attribute: Attribute.new: :package(TimeoutWasSet), :has_accessor, :type(Str), :name<$!unit>;
TimeoutWasSet.^add_attribute: Attribute.new: :package(TimeoutWasSet), :has_accessor, :type(Num), :name<$!value>;
TimeoutWasSet.^add_attribute: Attribute.new: :package(TimeoutWasSet), :has_accessor, :type(Str), :name<$!method>;

use Sourcing::Event;
TimeoutWasSet.^add_role: Sourcing::Event;
TimeoutWasSet.^compose;

sub EXPORT(--> Map()) {
	'TimeoutWasSet' => TimeoutWasSet
}
