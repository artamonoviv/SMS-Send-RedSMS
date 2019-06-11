use strict;
use warnings;
use Test::More tests => 4;
use SMS::Send::RedSMS;

subtest 'new() tests' => sub {
        plan tests => 5;

        ok(SMS::Send::RedSMS->can('new'), 'method new() available');

        my $driver = SMS::Send::RedSMS->new(
            _login    => 'test',
            _api => 'test',
            _sender => 'test'
        );

        is(ref($driver), 'SMS::Send::RedSMS', 'new() returns an instance of SMS::Send::RedSMS');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _login    => 'test',
                _api => 'test'
            );
        };

        like($@, qr/required/, 'Sender required');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _sender    => 'test',
                _api => 'test'
            );
        };

        like($@, qr/required/, 'Login required');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _login    => 'test',
                _sender => 'test'
            );
        };

        like($@, qr/required/, 'Api required');
    };

subtest 'send_sms() tests' => sub {
        plan tests => 3;

        ok(SMS::Send::RedSMS->can('send_sms'), 'method send_sms() available');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _login    => 'test',
                _api => 'test',
                _sender   => 'test'
            )->send_sms( to => 1 );
        };
        like($@, qr/to and text are required/, 'Missing parameters');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _login    => 'test',
                _api => 'test',
                _sender   => 'test'
            )->send_sms( text => 1 );
        };
        like($@, qr/to and text are required/, 'Missing parameters');

    };

can_ok('SMS::Send::RedSMS' ,'balance');

subtest 'status() tests' => sub {
        plan tests => 2;

        ok(SMS::Send::RedSMS->can('status'), 'method status() available');

        eval {
            my $driver = SMS::Send::RedSMS->new(
                _login    => 'test',
                _api => 'test',
                _sender   => 'test'
            )->status();
        };
        like($@, qr/At least one sms-id is required/, 'Missing parameters');
    };