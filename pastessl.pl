#!/usr/bin/env perl

use Mojolicious::Lite;
use DBI;
use File::Slurp;
use Mojolicious::Plugin::CertificateAuthority;

# set up the sqlite database
my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db","","", { RaiseError => 1, AutoCommit => 1 });
$dbh->do("CREATE TABLE IF NOT EXISTS pastes (id INTEGER PRIMARY KEY, content TEXT, expires TIMESTAMP)");

# set up the routes
get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

post '/' => sub {
    my $c = shift;
    my $content = $c->param('content');
    my $expires = time() + (60 * 60 * 24 * 60); # 60 days from now
    my $id = int(rand(1000000));
    my $sth = $dbh->prepare("INSERT INTO pastes (id, content, expires) VALUES (?, ?, ?)");
    $sth->execute($id, $content, $expires);
    write_file("pastes/$id.txt", $content);
    $c->redirect_to("/$id");
};

get '/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $sth = $dbh->prepare("SELECT * FROM pastes WHERE id = ?");
    $sth->execute($id);
    my $paste = $sth->fetchrow_hashref;
    if ($paste) {
        $c->render(template => 'paste', paste => $paste);
    } else {
        $c->render(text => "Paste not found");
    }
};

# start the app
app->start('daemon',
    listen => ['https://*:443?cert=/path/to/cert.pem&key=/path/to/key.pem'],
    certificate_authority => 'LetsEncrypt',
);

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>KISSmo Perl Version 0.7 stable</title>
    <link rel="stylesheet" href="https://ssl.gstatic.com/docs/script/css/add-ons1.css">
</head>
<body>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <center><br>
    <img src="https://i.imgur.com/zJuCchl.png" alt="the logo" width="340px" height="120px">
    <h1>KISSmo Perl Version 0.7 stable</h1></center>
    <center><form method="post">
        <textarea name="content" style="margin: 0px; width: 70%; height: 430px; background: aliceblue; color: black;"></textarea>
        </br>
	<input type="submit" value="Create paste"></center>
    </form>
</body>
</html>
@@ paste.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>Paste</title>
    <link rel="stylesheet" href="https://ssl.gstatic.com/docs/script/css/add-ons1.css">
</head>
<body>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <h1>Paste</h1>
    <pre></p><%= $paste->{content} %></p></pre>
    <p>Expires: <%= $paste->{expires} %></p>
</body>
</html>
