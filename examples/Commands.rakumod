use Sourcing::Command;

sub blablabla(Str :$data!) is sourcing-command {
	say "bla: $data";
}
