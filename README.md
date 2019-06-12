[![Build Status](https://travis-ci.com/artamonoviv/SMS-Send-RedSMS.svg?branch=master)](https://travis-ci.com/artamonoviv/SMS-Send-RedSMS)

# SMS::Send::RedSMS

SMS::Send::RedSMS - SMS::Send driver to send messages via RedSMS.ru (https://redsms.ru)

## VERSION

version 0.001

## SYNOPSIS

```
    use SMS::Send;
    my $api = SMS::Send->new('RedSMS',
        _login    => 'your login',
        _api => 'your api key',
        _sender => 'your approved sender name',
    );

    my $sent = $api->send_sms(
        'to'             => '+70001234567',
        'text'           => 'This is a test message'
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message: ', $@, "\n";
    }

    # Get info about last sent sms
    my $info = $api->{OBJECT}->{status};

    # Get sms-id of last sent sms
    print $api->{OBJECT}->{status}->{id};

    # Show your balance
    print $api->balance();

    # Get sms delivery status
    $status = $api->status('sms-id 1', 'sms-id 2', ..., 'sms-id N');
    print $status->{'sms-id 1'};

    # Show error text of the last failed operation
    # Caution: in Russian (as RedSMS.ru is a Russian-oriented service)!
    print $@;
```

## DESCRIPTION

SMS::Send driver for RedSMS - https://redsms.ru/

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the RedSMS HTTP API mechanism (lk.redsms.ru version) with JSON.

Be aware! The driver is intended only for lk.redsms.ru (not cp.redsms.ru) version of API.

## METHODS

### new

Constructor, takes argument pairs passed by SMS::Send, returns an SMS::Send::RedSMS object. 

```
    # Create a new sender using this driver
    my $api = SMS::Send->new('RedSMS',
        _login    => 'your login',
        _api => 'your api key',
        _sender => 'your approved sender name',
    );
```

Additional arguments that may be passed include:

#### _endpoints

A hashref with HTTP API endpoints. Default are:

```
    _endpoints =>
    {
        send=>'https://lk.redsms.ru/get/send.php',
        status=>'https://lk.redsms.ru/get/status.php',
        balance=>'https://lk.redsms.ru/get/balance.php',
        timestamp=>'https://lk.redsms.ru/get/timestamp.php'
    }
```

#### _timeout

The timeout in seconds for HTTP operations. Defaults to 10 seconds.

### send_sms

This method is actually called by SMS::Send when you call send_sms on it.

```
    my $sent = $api->send_sms(
        'to'             => '+70001234567',
        'text'           => 'This is a test message'
    );
```

Returns 1 if success, 0 otherwise.

Russian error text is stored in $@ variable.

### status

Get delivery statuses of sent messages. You should pass into at least one sms-id code.

```
    $status = $api->status('5602283620380000000001', '5602283620380000000002');
    print $status->{'5602283620380000000001'}; # 1 if delivered, 0 otherwise
    print $status->{'5602283620380000000002'};
```

Sms-id code of last sent sms can be gained through 'status' hashref after sending:

```
    print $api->{OBJECT}->{status}->{id};
```

### balance

Get your balance in rubles.
```
print $api->balance();
```

## BUGS AND LIMITATIONS

The driver is intended only for lk.redsms.ru (not cp.redsms.ru) version of API.

## AUTHOR

Ivan Artamonov, <ivan.s.artamonov {at} gmail.com>

## LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Ivan Artamonov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.