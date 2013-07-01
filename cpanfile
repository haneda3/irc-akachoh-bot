requires 'Data::Dump';
requires 'AnyEvent';
requires 'AnyEvent::IRC::Client';

on test => sub {
    requires 'Test::Perl::Critic';
};
