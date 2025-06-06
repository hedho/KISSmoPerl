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

get '/installation' => sub {
    my $c = shift;
    $c->render(template => 'installation');
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
    <title>KISSmo Perl Version 1.9 stable</title>
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>KISSmo Perl Version 1.9 stable</h1>
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
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://git.hax.al/KISSmoPerl/about/">Source code & About</a>.</p>
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
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

@@ installation.html.ep

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="HandheldFriendly" content="true">
    <title>Installation and Updates</title>
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
        .installation-instructions {
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
                <a class="nav-link" href="https://hax.al">Home</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="/installation">Installation and Updates</a>
            </li>
        </ul>
    </nav>
    <div class="container">
        <h1>Installation and Updates</h1>
        <div class="installation-instructions">
            <h2>KISSmo Perl Pastebin</h2>

<p>KISSmo Perl Pastebin is a simple pastebin service implemented in Perl using the Mojolicious framework. It allows users to create and share plain text snippets or code snippets easily. The service stores the pasted content in an SQLite database and provides various features such as expiration of pastes, viewing and downloading pastes, and raw access to the content.</p>

<h3>Prerequisites</h3>

<p>To run KISSmo Perl Pastebin, the following dependencies are required:</p>

<ul>
<li>Perl (5.10.1 or higher)</li>
<li>Mojolicious framework</li>
<li>DBI module</li>
<li>File::Slurp module</li>
<li>SQLite database</li>
</ul>

<p>Make sure you have Perl installed on your system and install the required modules using the CPAN or CPANM package manager.</p>

<h3>Installation</h3>

<ol>
<li>Clone the KISSmo Perl Pastebin repository from GitHub:</li>

<pre><code>$ git clone https://github.com/hedho/KISSmoPerl.git</code></pre>

<li>Change to the project directory:</li>

<pre><code>$ cd KISSmoPerl</code></pre>

<li>Install the required Perl modules:</li>

<pre><code>$ cpan Mojolicious DBI File::Slurp</code></pre>

<li>Create an SQLite database file named <code>pastes.db</code>:</li>

<pre><code>$ touch pastes.db</code></pre>

<pre><code>$ mkdir pastes</code></pre>
</ol>

<h3>Configuration</h3>

<p>The configuration for KISSmo Perl Pastebin is handled through the Perl script itself. You can modify the script directly to customize the behavior and appearance of the pastebin service. Some of the configurable options include:</p>

<ul>
<li>Database settings: You can modify the database connection parameters (<code>dbname</code>, <code>username</code>, <code>password</code>) in the line <code>$dbh-&gt;connect("dbi:SQLite:dbname=pastes.db","","", { RaiseError =&gt; 1, AutoCommit =&gt; 1 });</code> to match your environment.</li>
</ul>

<h3>Running the Service</h3>

<p>To start the KISSmo Perl Pastebin service, run the following command:</p>

<pre><code>$ ./pastebin.pl daemon</code></pre>

<p>The service will start running on the default port (3000) on your local machine. You can access the pastebin service by opening a web browser and visiting <a href="http://localhost:3000">http://localhost:3000</a>.</p>

<h3>Usage</h3>

<ol>
<li>Home Page: The home page provides a simple form where you can enter your content. The content can be any plain text or code snippet that you want to share. Enter the content in the provided textarea and click on the "Create paste" button.</li>
<li>View Paste: After creating a paste, you will be redirected to a page that displays the paste details. The content of the paste will be shown along with options to view the raw content or download the paste as a text file. The expiration time of the paste is also displayed.</li>
<li>Raw Content: Clicking on the "RAW" button will display the raw content of the paste in plain text format.</li>
<li>Download: Clicking on the "Download" button will prompt you to download the paste as a text file. The file will be named with the paste ID followed by the <code>.txt</code> extension.</li>
</ol>

<h3>Customization</h3>

<p>If you want to customize the appearance or behavior of the pastebin service, you can modify the templates located in the <code>__DATA__</code> section of the Perl script. The templates are written in Embedded Perl (EP) format and use HTML for markup. You can modify the HTML, CSS, and JavaScript code to match your requirements.</p>

<h3>Maintenance</h3>

<p>To manage the pastes stored in the database, you can use any SQLite database management tool or interact directly with the <code>pastes.db</code> file using the SQLite command-line tool.</p>

<h3>Conclusion</h3>

<p>KISSmo Perl Pastebin is a lightweight and easy-to-use pastebin service written in Perl. It provides a simple web interface for creating, sharing, and managing plain text.</p>

<br />
<a href="https://www.buymeacoffee.com/arianit"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=arianit&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>
<br />
Source link:<br />
<br />
<a href="https://www.buymeacoffee.com/arianit">https://www.buymeacoffee.com/arianit</a></p>

            <!-- Add the installation instructions here -->
            ...
        </div>
    </div>
    <footer class="footer">
        <p>This pastebin script has been developed by Arianit. The source code can be found at <a href="https://github.com/hedho/KISSmoPerl">GitHub</a>.</p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</body>
</html>
