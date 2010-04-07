package App::Lyra::AdEngine::ByArea;
use Moose;
use Lyra::Server::AdEngine::ByArea;
use Lyra::Log::Storage::File;
use namespace::autoclean;

with 
    'Lyra::Trait::App::WithLogger' => {
        loggers => [
            {
                prefix => 'impression',
            },
            {
                prefix => 'request',
            },
        ],
    },
    'Lyra::Trait::App::StandaloneServer'
;

has '+psgi_server' => (
    default => 'Twiggy'
);

has click_uri => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has dsn => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has user => (
    is => 'ro',
    isa => 'Str',
);

has password => (
    is => 'ro',
    isa => 'Str',
);

sub build_app {
    my $self = shift;

    my $cv = AE::cv;

    my $dbh = AnyEvent::DBI->new(
        $self->dsn,
        $self->user,
        $self->password,
        exec_server => 1,
        on_connect => sub {
            $cv->send;
        },
        RaiseError => 1,
        AutoCommit => 1,
    );

    $cv->recv;

    Lyra::Server::AdEngine::ByArea->new(
        dbh => $dbh,
        click_uri => $self->click_uri,
        templates_dir => './templates',
        request_log_storage => $self->build_request_log,
        impression_log_storage => $self->build_impression_log,
    )->psgi_app;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

App::Lyra::AdEngine::ByArea - Area-based AdEngine

=head1 SYNOPSIS

    lyra_adengine_byarea --dsn=dbi:mysql:dbname=lyra 

    # if you need to pass PSGI parameters, do so after --
    lyra_adengine_byarea \
        --dsn=dbi:mysql:dbname=lyra  \
        -- \
        --port=9999

=cut
