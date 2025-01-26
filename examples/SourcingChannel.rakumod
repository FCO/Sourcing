use Sourcing <no-commands>;

my $cmd-handler = start {
   my Channel $ch .= new;

   Sourcing<command>.emitter-sub = -> $cmd { $ch.send: $cmd }

   react whenever $ch -> $cmd {
      Sourcing<command>.handle: $cmd;
      done
   }
}

sub awaits-command-handler is export { await $cmd-handler }
