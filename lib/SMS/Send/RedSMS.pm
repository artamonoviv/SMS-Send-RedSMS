package SMS::Send::RedSMS;
use strict;
use warnings;
our $VERSION = '0.001';

use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode decode);
use JSON::MaybeXS qw(decode_json);
use URI::Escape qw( uri_escape );
use Carp qw(croak);

use base 'SMS::Send::Driver';

sub new {
    my ( $class, %args ) = @_;

    unless ( $args{'_login'} && $args{'_api'} && $args{'_sender'}) {
        croak '_login, _api, _sender are required';
    }

    my $self = bless \%args, $class;

    if (!exists($self->{_endpoints}))
    {
        $self->{_endpoints}->{send}='https://lk.redsms.ru/get/send.php';
        $self->{_endpoints}->{status}='https://lk.redsms.ru/get/status.php';
        $self->{_endpoints}->{balance}='https://lk.redsms.ru/get/balance.php';
        $self->{_endpoints}->{timestamp}='https://lk.redsms.ru/get/timestamp.php';
    }
    $self->{_timeout} = 10 if (!exists($self->{_timeout}));

    $self->{_ua} = LWP::UserAgent->new(
        agent => join( '/', $class, $VERSION ),
        timeout => $self->{_timeout}
    );

    return $self;
}

sub send_sms
{
    my ( $self, %args ) = @_;

    if (!$args{'to'} || !$args{'text'} )
    {
        croak 'to and text are required';
    }

    my ($response, $error_code, $status_text)=$self->_query($self->{_endpoints}->{send}.'?'.$self->_signature('phone'=>$args{to},'text'=>$args{text}, 'sender'=>$self->{_sender}));

    $self->{status}={to=>$args{to}, status=>$error_code, status_text=>$status_text, response=>$response, id=>0, cost=>0, count_sms=>0};

    if(!$error_code && $response)
    {
        if(ref($response) eq "ARRAY")
        {
            my $to=(keys (%{$response->[0]}))[0];
            $self->{status}->{to}=$to;
            $self->{status}->{id}=$response->[0]{$to}{id_sms};
            $self->{status}->{cost}=$response->[0]{$to}{cost};
            $self->{status}->{count_sms}=$response->[0]{$to}{count_sms};
        }
        return 1;
    }
    else
    {
        $@=$status_text;
        return 0;
    }
}

sub status
{
    my ( $self, @list ) = @_;

    if (!@list)
    {
        croak 'At least one sms-id is required';
    }

    my %status;
    map { $status{$_}=0 } @list;

    my ($response, $error_code, $status_text)=$self->_query($self->{_endpoints}->{status}.'?'.$self->_signature('state'=>join(",",@list)));

    if(!$error_code && $response)
    {
        foreach (grep {ref($response->{$_}) eq 'HASH'} keys %{$response})#todo
        {
            $status{$_}=1 if($response->{$_}->{status} eq "deliver");
        }
    }
    else
    {
        $@=$status_text;
    }
    return \%status;
}

sub balance
{
    my $self=$_[0];
    my ($response, $error_code, $status_text)=$self->_query($self->{_endpoints}->{balance}.'?'.$self->_signature());
    return $response->{money} if(!$error_code && $response && exists($response->{money}));
    $@=$status_text;
    return -1;
}

sub _signature
{
    my ( $self, %args ) = @_;

    if($self->_timestamp()=~/^\d{10}$/)
    {
        $args{login}=$self->{_login};
        $args{timestamp}=$self->{_timestamp};
        return (join '&', map {$_.'='.uri_escape($args{$_})}  sort keys %args)."&signature=".md5_hex((join '', map {$args{$_}}  sort keys %args).$self->{_api});
    }
    return undef;
}

sub _timestamp
{
    my $self=$_[0];
    if(!$self->{_timestamp} || $self->{_timestamp_time}+60-$self->{_timeout} <= time)
    {
        $self->{_timestamp}=($self->_query($self->{_endpoints}->{timestamp}))[0];
        $self->{_timestamp_time}=time;
    }
    return $self->{_timestamp};
}

sub _query
{
    my ( $self, $url ) = @_;

    my $response = $self->{_ua}->get($url)->content;

    if($response=~/^\{\"error\"\:(\d+)\}$/ && $1 && $1!=18)
    {
        my %status;
        $status{"000"}="Сервис отключен";
        $status{"1"}="Не указана подпись";
        $status{"2"}="Не указан логин";
        $status{"3"}="Не указан текст";
        $status{"4"}="Не указан телефон";
        $status{"5"}="Не указан отправитель";
        $status{"6"}="Некорректная подпись";
        $status{"7"}="Некорректный логин";
        $status{"8"}="Некорректное имя отправителя";
        $status{"9"}="Незарегистрированное имя отправителя";
        $status{"10"}="Неодобренное имя отправителя";
        $status{"11"}="В тексте содержатся запрещенные слова";
        $status{"12"}="Ошибка отправки СМС";
        $status{"13"}="Номер находится в стоп-листе. Отправка на этот номер запрещена";
        $status{"14"}="В запросе более 50 номеров";
        $status{"15"}="Не указана база";
        $status{"16"}="Не корректный номер";
        $status{"17"}="Не указаны ID СМС";
        $status{"18"}="Не получен статус";
        $status{"19"}="Пустой ответ";
        $status{"20"}="Номер уже существует";
        $status{"21"}="Отсутствует название";
        $status{"22"}="Шаблон уже существует";
        $status{"23"}="Не указан месяц (Формат: YYYY-MM)";
        $status{"24"}="Не указана временная метка";
        $status{"25"}="Ошибка доступа к базе";
        $status{"26"}="База не содержит номеров";
        $status{"27"}="Нет валидных номеров";
        $status{"28"}="Не указана начальная дата";
        $status{"29"}="Не указана конечная дата";
        $status{"30"}="Не указана дата (Формат: YYYY-MM-DD)";

        return (undef,$1,$status{$1});
    }

    return ($response,0,"OK") if ($response!~/{/);
    return (decode_json($response),0,"OK");
}

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::RedSMS - SMS::Send driver to send messages via RedSMS.ru service (https://redsms.ru)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

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

=head1 DESCRIPTION

SMS::Send driver for RedSMS - L<https://www.redsms.ru/>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the RedSMS HTTP API mechanism (lk.redsms.ru version) with JSON.

Be aware! The driver is intended only for lk.redsms.ru (not cp.redsms.ru) version of API.

=head1 METHODS

=head2 new

    # Create a new sender using this driver
    my $api = SMS::Send->new('RedSMS',
        _login    => 'your login',
        _api => 'your api key',
        _sender => 'your approved sender name',
    );

Additional arguments that may be passed include:

=over 3

=item _endpoints

A hashref with HTTP API endpoints. Default are:

    _endpoints=>
    {
        send=>'https://lk.redsms.ru/get/send.php',
        status=>'https://lk.redsms.ru/get/status.php',
        balance=>'https://lk.redsms.ru/get/balance.php',
        timestamp=>'https://lk.redsms.ru/get/timestamp.php'
    }

=item _timeout

The timeout in seconds for HTTP operations. Defaults to 10 seconds.

=back

=head2 send_sms

This method is actually called by L<SMS::Send> when you call send_sms on it.

    my $sent = $api->send_sms(
        'to'             => '+70001234567',
        'text'           => 'This is a test message'
    );

Returns 1 if success, 0 otherwise.

Russian error text is stored in $@ variable.

=head2 status

Get delivery statuses of sent messages. You should pass into at least one sms-id code.

    $status = $api->status('5602283620380000000001', '5602283620380000000002', '5602283620380000000003');
    print $status->{'5602283620380000000001'}; # 1 if delivered, 0 otherwise
    print $status->{'5602283620380000000002'};

Sms-id code of last sent sms can be gained through 'status' hashref after sending:

    print $api->{OBJECT}->{status}->{id};

=head2 balance

Get your balance in rubles.

    print $api->balance();

=head1 BUGS AND LIMITATIONS

The driver is intended only for lk.redsms.ru (not cp.redsms.ru) version of API.

=head1 AUTHOR

Ivan Artamonov, <ivan.s.artamonov {at} gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Ivan Artamonov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
