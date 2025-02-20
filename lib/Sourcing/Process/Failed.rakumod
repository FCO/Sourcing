use Metamodel::EventHOW;
my \Failed = Metamodel::EventHOW.new_type: :name<Sourcing::Process::Failed>;

Failed.^add_attribute: Attribute.new: :package(Failed), :has_accessor, :type(Str), :name<$!transaction-id>;
Failed.^add_attribute: Attribute.new: :package(Failed), :has_accessor, :type(Str), :name<$!error>;

use Sourcing::Event;
Failed.^add_role: Sourcing::Event;
Failed.^compose;

sub EXPORT(--> Map()) {
	Failed => Failed
}
