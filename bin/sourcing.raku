use Sourcing::Manager;
use UUID::V4;
use Nats;
use Nats::Client;
use Nats::Subscriptions;
use JSON::Fast;
use lib ".";

multi MAIN {

	my $manager = Sourcing::Manager.new: :transaction-id(Str);

	my Nats $nats .= new;
	my $subscriptions = subscriptions {
		subscribe -> "register_class" {
			CATCH {
				default {
					message.reply-json: %( :error(.message), :error-type(.^name) )
				}
			}
			my Str $type = message.payload;
			my $answer = $manager.register-class: $type;
			message.reply-json: $answer
		}

		subscribe -> "describe_class" {
			CATCH {
				default {
					message.reply-json: %( :error(.message), :error-type(.^name) )
				}
			}
			my Str $type  = message.payload;
			message.reply-json: $manager.describe-class: $type
		}

		subscribe -> "create_object" {
			CATCH {
				default {
					message.reply-json: %( :error(.message), :error-type(.^name) )
				}
			}
			my :(Str :$type, :%ids) := |message.json;
			my $resp = $manager.create-object: $type, |%ids;
			message.reply-json: $resp;
		}

		subscribe -> "command" {
			CATCH {
				default {
					message.reply-json: %( :error(.message), :error-type(.^name) )
				}
			}
			my :(:$class, :$method, :%ids, :@list, :%hash) := |message.json;
			my $instance = $manager.get-instance: $class, %ids;
			message.reply-json: $instance."$method"(|@list, |%hash)
		}

		subscribe -> "query" {
			CATCH {
				default {
					message.reply-json: %( :error(.message), :error-type(.^name) )
				}
			}
			my :(:$class, :$method, :%ids, :@list, :%hash) := |message.json;
			my $instance = $manager.get-instance: $class, %ids;
			message.reply-json: $instance."$method"(|@list, |%hash)
		}
	}

	my $client = Nats::Client.new: :$nats, :$subscriptions;

	$client.start;

	react {
		whenever signal(SIGINT) { $client.stop; exit }
	}
}
