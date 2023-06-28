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
        my $id = int(rand(1000000000));
        my $sth = $dbh->prepare("INSERT INTO pastes (id, content, expires) VALUES (?, ?, ?)");
        $sth->execute($id, $content, $expires);
        write_file("pastes/$id.txt", $content);
        $c->redirect_to("/$id");
    } else {
        $c->render(template => 'invalid_content');
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
        $c->res->code(404);
        $c->render(template => 'invalid_link');
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
        $c->res->code(404);
        $c->render(template => 'invalid_link');
    }
};

get '/download/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $sth = $dbh->prepare("SELECT content FROM pastes WHERE id = ?");
    $sth->execute($id);
    my ($content) = $sth->fetchrow_array;
    if ($content) {
        $c->res->headers->content_type('text/plain');
        $c->res->headers->content_disposition("attachment; filename=$id.txt");
        $c->render(text => $content);
    } else {
        $c->res->code(404);
        $c->render(template => 'invalid_link');
    }
};

# start the app
app->start;

sub format_expires {
    my $expires = shift;
    my $current_time = time();

    if ($expires > $current_time) {
        my $seconds_remaining = $expires - $current_time;
        my $days = int($seconds_remaining / (60 * 60 * 24));
        my $hours = int(($seconds_remaining % (60 * 60 * 24)) / (60 * 60));
        my $minutes = int(($seconds_remaining % (60 * 60)) / 60);
        return sprintf("%d days, %02d:%02d", $days, $hours, $minutes);
    }

    return 'Expired';
}

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>KISSmo Perl Version 1.1.7 stable</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #9f9f9f33;
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
            background-color: #00a6ff;
            border-color: #00a6ff;
        }
        .btn-primary:hover {
            background-color: #0069d9;
            border-color: #0062cc;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            background-color: #00a6ff;
            color: #fff;
            width: 100%;
            position: relative;
            bottom: 0;
            left: 0;
            padding: 15px;
        }
        .footer a {
            color: #ffc107; /* Set the link color to bright yellow */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <a class="navbar-brand" href="/">KISSMO</a>
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>KISSmo Perl Version 1.1.7 stable</h1>
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
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Paste</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #9f9f9f33;
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
            background-color: #00a6ff;
            color: #fff;
            width: 100%;
            position: relative;
            bottom: 0;
            left: 0;
            padding: 15px;
        }
        .footer a {
            color: #ffc107; /* Set the link color to bright yellow */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <a class="navbar-brand" href="/">KISSMO</a>
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>Paste</h1>
        <pre><%= $paste->{content} %></pre>
        <a href="/raw/<%= $paste->{id} %>" class="btn btn-primary">RAW</a>
        <a href="/download/<%= $paste->{id} %>" class="btn btn-primary">Download</a>
        <p>Expires: <%= $paste->{expires_human} %></p>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
@@ invalid_content.html.ep

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Invalid Content</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #9f9f9f33;
        }
        .container {
            max-width: 800px;
            margin-top: 50px;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        .alert {
            margin-top: 30px;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            background-color: #00a6ff;
            color: #fff;
            width: 100%;
            position: relative;
            bottom: 0;
            left: 0;
            padding: 15px;
        }
        .footer a {
            color: #ffc107; /* Set the link color to bright yellow */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <a class="navbar-brand" href="/">KISSMO</a>
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>Invalid Content</h1>
        <div class="alert alert-danger" role="alert">
            Please enter valid content.
        </div>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho/KISSmoPerl">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
@@ invalid_link.html.ep

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Invalid Link</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #9f9f9f33;
        }
        .container {
            max-width: 800px;
            margin-top: 50px;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        .alert {
            margin-top: 30px;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            background-color: #00a6ff;
            color: #fff;
            width: 100%;
            position: relative;
            bottom: 0;
            left: 0;
            padding: 15px;
        }
        .footer a {
            color: #ffc107; /* Set the link color to bright yellow */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <a class="navbar-brand" href="/">KISSMO</a>
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>Invalid Link</h1>
        <div class="alert alert-danger" role="alert">
            The link you requested is invalid or has expired.
        </div>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho/KISSmoPerl">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
@@ not_found.html.ep

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Invalid Link</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <style>
        body {
            background-color: #9f9f9f33;
        }
        .container {
            max-width: 800px;
            margin-top: 50px;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        .alert {
            margin-top: 30px;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            background-color: #00a6ff;
            color: #fff;
            width: 100%;
            position: relative;
            bottom: 0;
            left: 0;
            padding: 15px;
        }
        .footer a {
            color: #ffc107; /* Set the link color to bright yellow */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <a class="navbar-brand" href="/">KISSMO</a>
        <ul class="navbar-nav mr-auto">
            <li class="nav-item">
                <a class="nav-link" href="/">Home</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>Not Found</h1>
        <div class="alert alert-danger" role="alert">
            The page you requested was not found.
        </div>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho/KISSmoPerl">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
