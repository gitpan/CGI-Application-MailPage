# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Application::MailPage;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $options = {
               page => 'http://usused/test.html',
               rm => 'send_mail',
               name => 'Sammy Sender',
               from_email => 'sam@tregar.com',
               subject => 'Test Subject',
               to_emails => 'sam@tregar.com',
               note => '',
               format => 'both_attachment',
              };

# test a simple usage

my $query = CGI->new($options);
my $mail;
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ /This is the test HTML page/) {
  die "not ok 2\n";
}                                                         
print "ok 2\n";                                                         

# test the other formats
$options->{format} = 'html';
$query = CGI->new($options);
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ /<H1>This is the test HTML page<\/H1>/) {
  die "not ok 3\n";
}    
print "ok 3\n";                                                         

$options->{format} = 'html_attachment';
$query = CGI->new($options);
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ /<H1>This is the test HTML page<\/H1>/) {
  die "not ok 4\n";
}    
print "ok 4\n";     

$options->{format} = 'text';
$query = CGI->new($options);
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ /This is the test HTML page/) {
  die "not ok 5\n";
}    
print "ok 5\n";                                                         

$options->{format} = 'text_attachment';
$query = CGI->new($options);
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ /This is the test HTML page/) {
  die "not ok 6\n";
}    
print "ok 6\n";     


$options->{format} = 'url';
$query = CGI->new($options);
my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                        }
                                              );
eval {
  $mailpage->run();
};
if ($@ !~ /Mail Dumped/) {
  die $@;
}
if ($mail !~ m!http://usused/test.html!) {
  die "not ok 7\n";
}    
print "ok 7\n";     

