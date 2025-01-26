use Sourcing::Command <no-commands>;

my $cmd-handler = start {
   my Channel $ch .= new;

   Sourcing::Command<command>.emitter-sub = -> $cmd { $ch.send: $cmd }

   react whenever $ch -> $cmd {
      Sourcing::Command<command>.handle: $cmd;
      done
   }
}

sub awaits-command-handler is export { await $cmd-handler }
