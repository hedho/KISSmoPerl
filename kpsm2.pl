#!/usr/bin/env perl

use Mojolicious::Lite;
use DBI;
use Digest::SHA qw(sha1_hex);

my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", { RaiseError => 1 });

my $table_exists = $dbh->selectrow_array("SELECT name FROM sqlite_master WHERE type='table' AND name='pastes'");
if (!$table_exists) {
    $dbh->do("CREATE TABLE pastes (id TEXT PRIMARY KEY, content TEXT)");
}

get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

post '/create' => sub {
    my $c = shift;
    my $content = $c->param('content');
    my $id = sha1_hex(time . $content);
    $dbh->do("INSERT INTO pastes (id, content) VALUES (?, ?)", undef, $id, $content);
    $c->redirect_to("/view/$id");
};

get '/view/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $content = $dbh->selectrow_array("SELECT content FROM pastes WHERE id = ?", undef, $id);
    $c->render(text => $content);
};

get '/search' => sub {
    my $c = shift;
    my $query = $c->param('q');
    my $results = $dbh->selectall_arrayref("SELECT id FROM pastes WHERE content LIKE ?", { Slice => {} }, "%$query%");
    $c->render(template => 'search', results => $results);
};

app->start;
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>Pastebin</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <h1>Create a new paste</h1>
    <form action="/create" method="post">
        <textarea name="content" rows="10" cols="80"></textarea>
        <input type="submit" value="Create">
    </form>
    <h1>Search for a paste</h1>
    <form action="/search" method="get">
        <input type="text" name="q">
        <input type="submit" value="Search">
    </form>
</body>
</html>

@@ search.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>Pastebin</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <h1>Search Results</h1>
    <ul>
    % for my $result (@$results) {
