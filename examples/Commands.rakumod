use Sourcing;

sub blablabla(Str :$data!) is sourcing-command is export {
	say "bla: $data";
}

sub blebleble(Str :$data!) is sourcing-command is export {
	say "ble: $data";
}
