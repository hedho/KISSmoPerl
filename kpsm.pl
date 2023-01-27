#!/usr/bin/perl

use CGI;
use strict;
use File::Slurp;

my $q = CGI->new;
my $paste = $q->param('paste');
my $search = $q->param('search');
my $filename = time . '.txt';

if ($paste) {
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $paste;
    close $fh;

    print $q->redirect("http://localhost/pastes/$filename");
} elsif ($search) {
    my @files = <*.txt>;
    my @matches;
    foreach my $file (@files) {
        my $content = read_file($file);
        if ($content =~ /$search/i) {
            push @matches, $file;
        }
    }

    print $q->header,
          $q->start_html(-title => 'Simple Pastebin', -style => {-src => 'materialize.css'}),
          $q->start_form,
          $q->textfield(-name => 'search', -default => $search),
          $q->submit('Search'),
          $q->end_form;

    if (@matches) {
        print "<ul>\n";
        foreach my $match (@matches) {
            print "<li><a href='/pastes/$match'>$match</a></li>\n";
        }
        print "</ul>\n";
    } else {
        print "No matches found.\n";
    }

    print $q->end_html;
} else {
    print $q->header,
          $q->start_html(-title => 'Simple Pastebin', -style => {-src => 'materialize.css'}),
          $q->start_form,
          $q->textarea(-name => 'paste', -default => '', -rows => 10, -columns => 50),
          $q->br,
          $q->submit,
          $q->end_form,
          $q->end_html;
}
