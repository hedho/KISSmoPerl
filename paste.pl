#!/usr/bin/env perl

use Mojolicious::Lite;
use DBI;
use File::Slurp;

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

    # Trim leading and trailing whitespace
    $content =~ s/^\s+|\s+$//g;

    if ($content =~ /\w/) {  # Check if content contains any word character
        my $expires = time() + (60 * 60 * 24 * 60); # 60 days from now
        my $id = int(rand(1000000));
        my $sth = $dbh->prepare("INSERT INTO pastes (id, content, expires) VALUES (?, ?, ?)");
        $sth->execute($id, $content, $expires);
        write_file("pastes/$id.txt", $content);
        $c->redirect_to("/$id");
    } else {
        $c->render(text => "Invalid paste content");
    }
};

get '/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $sth = $dbh->prepare("SELECT * FROM pastes WHERE id = ?");
    $sth->execute($id);
    my $paste = $sth->fetchrow_hashref;
    if ($paste) {
        $paste->{expires_human} = format_expires($paste->{expires});
        $c->render(template => 'paste', paste => $paste);
    } else {
        $c->render(text => "Paste not found");
    }
};

get '/raw/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $sth = $dbh->prepare("SELECT content FROM pastes WHERE id = ?");
    $sth->execute($id);
    my ($content) = $sth->fetchrow_array;
    if ($content) {
        $c->res->headers->content_type('text/plain');
        $c->render(text => $content);
    } else {
        $c->render(text => "Paste not found");
    }
};

# start the app
app->start;

sub format_expires {
    my $expires = shift;
    my $current_time = time();

    if ($expires > $current_time) {
        my $remaining_seconds = $expires - $current_time;
        my $remaining_days = int($remaining_seconds / (60 * 60 * 24));
        return "In $remaining_days days";
    } else {
        return "Expired";
    }
}

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<?php
   if (substr_count($_SERVER[HTTP_ACCEPT_ENCODING], gzip))
   ob_start(ob_gzhandler);
   else ob_start();
?>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>KISSmo Perl Version 1.1 stable</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
            margin-top: 50px;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        textarea {
            width: 100%;
            height: 300px;
            resize: none;
        }
        .btn-primary {
            background-color: #007bff;
            border-color: #007bff;
        }
        .btn-primary:hover {
            background-color: #0069d9;
            border-color: #0062cc;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>KISSmo Perl Version 1.1 stable</h1>
        <form method="post">
            <div class="form-group">
                <textarea name="content" class="form-control" placeholder="Enter your content" rows="10"></textarea>
            </div>
            <div class="text-center">
                <button type="submit" class="btn btn-primary">Create paste</button>
            </div>
        </form>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho/KISSmoPerl">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>

@@ paste.html.ep
<!DOCTYPE html>
<?php
   if (substr_count($_SERVER[HTTP_ACCEPT_ENCODING], gzip))
   ob_start(ob_gzhandler);
   else ob_start();
?>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Paste</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
            margin-top: 50px;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        pre {
            background-color: #fff;
            border: 1px solid #ccc;
            padding: 15px;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Paste</h1>
        <pre><%= $paste->{content} %></pre>
        <a href="/raw/<%= $paste->{id} %>" class="btn btn-primary">RAW</a>
        <p>Expires: <%= $paste->{expires_human} %></p>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
