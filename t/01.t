use strict;
use warnings;
use Test::More (tests => 8);

require_ok('CGI');
require_ok('CGI::Application::MailPage');
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

$ENV{CGI_APP_RETURN_ONLY} = 1;


# 2 - test a the 'both_attachment' format
{
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /This is the test HTML page/, 'Test page as both');
}

# 3 -test a the 'html' format
{
    $options->{format} = 'html';
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /<H1>This is the test HTML page<\/H1>/, 'Test page as HTML');
}

# 4 -test a the 'html_attachment' format
{
    $options->{format} = 'html_attachment';
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /<H1>This is the test HTML page<\/H1>/, 'Test page as HTML attachment');
}

# 5 -test a the 'text' format
{
    $options->{format} = 'text';
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /This is the test HTML page/, 'Test page as text');
}

# 6 -test a the 'text_attachment' format
{
    $options->{format} = 'text_attachment';
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /This is the test HTML page/, 'Test page as text_attachment');
}


# 7 -test a the 'url' format
{
    $options->{format} = 'url';
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
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://usused/test.html!, 'Test page as url');
}

