#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Data::Dump qw/dump/;
use AnyEvent;
use AnyEvent::IRC::Client;

use FindBin;
use lib "$FindBin::Bin/lib";

my $irc_conf = do 'config.irc.pl' or die "$!";

dump($irc_conf);

my $irc_server = $irc_conf->{server};
my $irc_channels = $irc_conf->{channels};

my $ac;
my $irc;

while (1) {
    sleep 3;

    $ac = AnyEvent->condvar;
    $irc = AnyEvent::IRC::Client->new;

    irc_connect();

    $ac->recv;
}

sub irc_connect {
    say "irc_connect";
    # SSL使用時？
    #$irc->enable_ssl;
    $irc->connect($irc_server->{host}, $irc_server->{port}, {
            nick => $irc_server->{nick}, user => $irc_server->{user}, real => $irc_server->{real}
        });

    foreach my $name (keys $irc_channels) {
        my $password = $irc_channels->{$name}->{password} // '';
        $irc->send_srv("JOIN", "#$name", $password);
    };

    $irc->reg_cb( connect    => sub { say "connected"; } );
    $irc->reg_cb( registered => sub { say "registered";} );
    $irc->reg_cb(
        disconnect => sub {
            say "disconnect";
            $ac->send;
        }
    );
    $irc->reg_cb(
        publicmsg => sub {
            my ($irc, $channel, $msg) = @_;

            my $is_notice = $msg->{command} eq "NOTICE";
            my $message = $msg->{params}->[1] // '';

            if (is_call_me($irc->nick, $message)) {
                $irc->disconnect;
                return;
            }
        },
        irc_notice => sub {
        },
    );
}

sub is_call_me {
    my ($nick, $message) = @_;

    if ($message =~ /$nick/) {
        return 1;
    }

    return;
}


