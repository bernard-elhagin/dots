package Tidal::Client;
use v5.36;
use Exporter 'import';
use Digest::SHA    qw(sha256_hex sha256);
use Encode         qw(encode);
use Fcntl          qw(:DEFAULT :flock);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use File::Temp     qw(tempfile);
use IO::Socket::INET;
use IO::Select;
use JSON::PP     ();
use MIME::Base64 qw(encode_base64url);
use POSIX        qw(isfinite);
use Time::HiRes  qw(time sleep clock_gettime CLOCK_MONOTONIC);
use Time::Local  qw(timegm);

our @EXPORT_OK = qw(api pages data_list load save digest legacy_digest json state_dir lock_state
    escape query uuid progress login http_status);
use constant API       => 'https://openapi.tidal.com/v2';
use constant TOKEN_URL => 'https://auth.tidal.com/v1/oauth2/token';
use constant CALLBACK  => 'http://127.0.0.1:8765/callback';
use constant SCOPES    => 'playlists.read playlists.write search.read collection.read';

sub state_dir()        { ( $ENV{XDG_STATE_HOME} // "$ENV{HOME}/.local/state" ) . '/tidal-playlist' }
sub json()             { JSON::PP->new->utf8->canonical->allow_nonref }
sub progress($message) { say STDERR $message }

sub read_bytes($path) {
    open my $file, '<:raw', $path or die "Cannot read $path: $!\n";
    local $/;
    return readline($file) // '';
}

sub load($path) {
    my $result = eval { json()->decode( read_bytes($path) ) };
    die "Cannot read JSON from $path: $@" if $@;

    return $result;
}

sub save( $path, $data ) {
    my $bytes = json()->pretty->encode($data);
    make_path( dirname($path), { mode => 0700 } );
    my ( $file, $temp ) = tempfile( '.tidal-XXXXXXXX', DIR => dirname($path), UNLINK => 1 );
    binmode( $file, ':raw' );
    print {$file} $bytes   or die "Cannot write $path: $!\n";
    close($file)           or die "Cannot close temporary file for $path: $!\n";
    rename( $temp, $path ) or die "Cannot replace $path: $!\n";
}

sub digest($value) { sha256_hex( json()->ascii->encode($value) ) }

# Python's legacy audio filenames and create fingerprints use ASCII JSON.
sub legacy_digest($value) {
    my $bytes = json()->ascii->encode($value);
    $bytes =~ s/("(?:[^"\\]|\\.)*")|([,:])/defined($1) ? $1 : "$2 "/ge;
    return sha256_hex($bytes);
}

sub lock_state() {
    make_path( state_dir(), { mode => 0700 } );
    sysopen( my $lock, state_dir() . '/operation.lock', O_CREAT | O_RDWR, 0600 )
        or die "Cannot open operation lock: $!\n";
    flock( $lock, LOCK_EX | LOCK_NB ) or die "Another tidal-playlist operation is running.\n";

    return $lock;
}

sub random_bytes($size) {
    open my $file, '<:raw', '/dev/urandom' or die "Cannot open random source: $!\n";
    read( $file, my $value, $size ) == $size or die "Cannot generate random bytes\n";

    return $value;
}

sub uuid() {
    my @bytes = unpack 'C*', random_bytes(16);
    $bytes[6] = ( $bytes[6] & 15 ) | 64;
    $bytes[8] = ( $bytes[8] & 63 ) | 128;
    return join '-', unpack 'H8 H4 H4 H4 H12', pack 'C*', @bytes;
}

sub escape($value) {
    my $bytes = encode( 'UTF-8', $value );
    $bytes =~ s/([^A-Za-z0-9._~-])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

sub query(%fields) {
    return join '&', map { escape($_) . '=' . escape( $fields{$_} ) } sort keys %fields;
}

sub api_path($path) {
    $path =~ s{\Ahttps://openapi\.tidal\.com(?=/)}{};
    $path =~ s{\A/v2(?=/)}{};
    die "Refusing invalid or off-origin TIDAL API path.\n"
        unless $path =~ m{\A/(?!/)[^\x00-\x20#\\]*\z} && $path !~ m{/\.\.};
    return $path;
}

sub curl_option($value) {
    $value =~ s/([\\"])/\\$1/g;
    $value =~ s/\n/\\n/g;
    $value =~ s/\r/\\r/g;
    return qq{"$value"};
}

sub transport( $method, $url, $headers, $body ) {
    my $dir = File::Temp->newdir();

    # Supply credentials on stdin, not in the process argument list. Never follow redirects.
    open my $curl, '|-', 'curl', '-q', '--silent', '--max-time', '30',
        '--proto', '=https', '--globoff', '--dump-header', "$dir/headers",
        '--output', "$dir/body", '--config', '-'
        or die "Cannot run curl: $!\n";
    local $SIG{PIPE} = 'IGNORE';
    binmode( $curl, ':raw' );
    my @config = ( 'url = ' . curl_option($url), 'request = ' . curl_option($method) );
    push @config, map { 'header = ' . curl_option("$_: $headers->{$_}") } sort keys %$headers;
    push @config, 'data-binary = ' . curl_option($body) if defined $body;
    my $sent = print {$curl} join( "\n", @config ), "\n";
    return unless close($curl) && $sent;
    my $header   = read_bytes("$dir/headers");
    my @statuses = $header =~ /^HTTP\/\S+\s+(\d{3})/mg;
    my @delays   = $header =~ /^Retry-After:[ \t]*([^\r\n]+)/img;
    return ( $statuses[-1] // 0, read_bytes("$dir/body"), $delays[-1] );
}

sub retry_delay( $value, $attempt ) {
    return 2**$attempt unless defined $value;
    if ( $value =~ /\A\d+(?:\.\d+)?\z/ && isfinite( 0 + $value ) ) {
        return 0 + $value;
    }
    if ( $value =~ /\A\w{3}, (\d\d) (\w{3}) (\d{4}) (\d\d):(\d\d):(\d\d) GMT\z/ ) {
        my ( $day, $month, $year, $hour, $minute, $second ) = ( $1, $2, $3, $4, $5, $6 );
        my %month_index;
        @month_index{qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)} = ( 0 .. 11 );
        my $delay =
            eval { timegm( $second, $minute, $hour, $day, $month_index{$month}, $year ) - time };
        return $delay > 0 ? $delay : 0 if defined $delay;
    }

    return 2**$attempt;
}

sub http_status($error) { "$error" =~ /\ATIDAL HTTP (\d+):/ ? 0 + $1 : 0 }

sub request( $method, $url, $payload = undef, %options ) {
    my ( $form, $token, $key, $deadline ) = @options{qw(form token key deadline)};
    my $type    = $form ? 'application/x-www-form-urlencoded' : 'application/vnd.api+json';
    my %headers = ( Accept => $form ? 'application/json' : $type );
    $headers{Authorization}     = "Bearer $token" if defined $token;
    $headers{'Idempotency-Key'} = $key            if defined $key;
    $headers{'Content-Type'}    = $type           if defined $payload;
    my $body  = defined $payload ? ( $form ? query(%$payload) : json()->encode($payload) ) : undef;
    my $retry = !$form && ( $method eq 'GET' || defined $key );

    for my $attempt ( 0 .. 2 ) {
        die "Write recovery deadline reached. Inspect the saved operation before retrying.\n"
            if defined($deadline) && time + 30 >= $deadline;
        my ( $status, $raw, $retry_after ) = transport( $method, $url, \%headers, $body );
        if ( $status && $status >= 200 && $status < 300 ) {
            return {} unless length $raw;
            my $result = eval { json()->decode($raw) };
            die "TIDAL returned invalid JSON. Saved write keys are retained.\n" if $@;

            return $result;
        }
        if (   $retry
            && $attempt < 2
            && ( !$status || grep { $status == $_ } qw(429 500 502 503 504) ) ) {
            my $delay = retry_delay( $retry_after, $attempt );
            die "TIDAL HTTP $status: Retry after $delay seconds.\n" if $delay > 30;
            sleep($delay);
            next;
        }
        die "Network request failed. Saved write keys are retained.\n" unless $status;
        die "TIDAL HTTP $status: OAuth failed. Check scopes/callback or run login again.\n"
            if $form;
        my $detail = eval {
            join ' / ',
                map { $_->{detail} // $_->{title} // $_->{code} // '' }
                ( json()->decode($raw)->{errors} // [] )->@*;
        } // '';
        $detail =~ s/\Q$token\E/[redacted]/g if $token;
        $detail =~ s/[\x00-\x1f\x7f]/ /g;
        die "TIDAL HTTP $status: " . ( substr( $detail, 0, 700 ) || 'Request failed' ) . "\n";
    }
}

sub store_tokens( $response, $client, $previous = {} ) {
    die "OAuth response did not contain an access token.\n" unless $response->{access_token};
    $response->{refresh_token} //= $previous->{refresh_token};
    $response->{scope}         //= $previous->{scope} // '';
    $response->{client_id}  = $client;
    $response->{expires_at} = time + ( $response->{expires_in} // 3600 );
    save( state_dir() . '/tokens.json', $response );
    return $response->{access_token};
}

sub access_token( $force = 0 ) {
    my $path = state_dir() . '/tokens.json';
    die "Run tidal-playlist login first.\n" unless -f $path;
    my $tokens = load($path);
    return $tokens->{access_token} if !$force && ( $tokens->{expires_at} // 0 ) >= time + 60;
    die "Login expired. Run tidal-playlist login again.\n" unless $tokens->{refresh_token};
    my $client = $tokens->{client_id};
    return store_tokens(
        request(
            'POST',
            TOKEN_URL,
            {
                grant_type    => 'refresh_token',
                refresh_token => $tokens->{refresh_token},
                client_id     => $client
            },
            form => 1
        ),
        $client, $tokens
    );
}

sub api( $method, $path, $payload = undef, %options ) {
    my $url    = API . api_path($path);
    my $result = eval { request( $method, $url, $payload, %options, token => access_token() ) };
    my $error  = $@;
    return $result unless $error;
    die $error     unless http_status($error) == 401;

    return request( $method, $url, $payload, %options, token => access_token(1) );
}

sub pages( $path, $visit, $limit = 100, $bounded = 0 ) {
    my %seen;
    for ( 1 .. $limit ) {
        $path = api_path($path);
        die "TIDAL returned a repeated pagination link.\n" if $seen{$path}++;
        my $doc = api( 'GET', $path );
        $visit->($doc);
        my $next = ( $doc->{links} // {} )->{next};
        $next = $next->{href} if ref($next) eq 'HASH';
        return unless $next;
        $path = $next;
    }
    die "Pagination exceeded $limit pages. Refusing an incomplete result.\n" unless $bounded;
}

sub data_list($doc) {
    my $data = $doc->{data};
    return ref($data) eq 'HASH' ? ($data) : ref($data) eq 'ARRAY' ? @$data : ();
}

sub callback_params( $target, $state ) {
    my ( $path, $query ) = split /\?/, $target, 2;
    return unless $path eq '/callback' && defined $query;
    my %params;
    for my $pair ( split /&/, $query ) {
        my ( $key, $value ) = split /=/, $pair, 2;
        next unless defined $value;
        $value =~ tr/+/ /;
        $value =~ s/%([a-f0-9]{2})/chr(hex($1))/ige;
        return if exists $params{$key};
        $params{$key} = $value;
    }
    return unless sha256( $params{state} // '' ) eq sha256($state);
    return \%params if $params{code} || $params{error};

    return;
}

sub login($client) {
    my $verifier = encode_base64url( random_bytes(64) );
    my $state    = encode_base64url( random_bytes(32) );
    my $server   = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 8765,
        Listen    => 4,
        ReuseAddr => 1
    ) or die "Cannot listen on callback port 8765: $!\n";
    my $url = 'https://login.tidal.com/authorize?'
        . query(
        response_type         => 'code',
        client_id             => $client,
        redirect_uri          => CALLBACK,
        scope                 => SCOPES,
        code_challenge_method => 'S256',
        code_challenge        => encode_base64url( sha256($verifier) ),
        state                 => $state
        );
    progress("Open this URL in a browser on this computer and approve access:\n$url");
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 300;
    my $result;
    while ( clock_gettime(CLOCK_MONOTONIC) < $deadline && !$result ) {
        next unless IO::Select->new($server)->can_read(1);
        my $connection = $server->accept or next;
        my $buffer     = '';
        my $until      = clock_gettime(CLOCK_MONOTONIC) + 2;
        while ( length($buffer) < 8192
            && $buffer !~ /\r?\n\r?\n/
            && clock_gettime(CLOCK_MONOTONIC) < $until ) {
            last unless IO::Select->new($connection)->can_read(.2);
            last unless sysread( $connection, my $part, 1024 );
            $buffer .= $part;
        }
        $result = callback_params( $1, $state )
            if $buffer =~ /\AGET ([^\s]+) HTTP\/1\.[01]\r?\n/;
        my $status = $result ? '200 OK' : '400 Bad Request';
        my $message =
            $result ? 'Login response received. Return to your terminal.' : 'Invalid callback.';
        local $SIG{PIPE} = 'IGNORE';
        print {$connection}
            "HTTP/1.1 $status\r\nContent-Type: text/plain\r\nCache-Control: no-store\r\n"
            . 'Content-Length: '
            . length($message)
            . "\r\nConnection: close\r\n\r\n$message";
        close $connection;
    }
    close $server;
    die "Login timed out after five minutes. Run login again.\n" unless $result;
    die "TIDAL declined authorization. Check your app settings.\n" if $result->{error};
    store_tokens(
        request(
            'POST',
            TOKEN_URL,
            {
                grant_type    => 'authorization_code',
                client_id     => $client,
                code          => $result->{code},
                redirect_uri  => CALLBACK,
                code_verifier => $verifier
            },
            form => 1
        ),
        $client
    );
    return { connected => JSON::PP::true };
}

1;
