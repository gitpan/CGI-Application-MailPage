use strict;
use warnings;
use Test::More (tests => 18);

require_ok('CGI');
require_ok('CGI::Application::MailPage');
my $options = {
               page         => 'http://unused/test.html',
               rm           => 'send_mail',
               name         => 'Sammy Sender',
               from_email   => 'sam@tregar.com',
               subject      => 'Test Subject',
               to_emails    => 'sam@tregar.com',
               note         => '',
               format       => 'both_attachment',
              };

$ENV{CGI_APP_RETURN_ONLY} = 1;


# 3 - test a the 'both_attachment' format
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

# 4 -test a the 'html' format
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

# 5 -test a the 'html_attachment' format
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

# 6 -test a the 'text' format
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

# 7 -test a the 'text_attachment' format
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


# 8 -test a the 'url' format
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
    ok($mail =~ m!http://unused/test.html!, 'Test page as url');
}

# 9 - test an acceptable domain in 'acceptable_domains' option
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
                                                         acceptable_domains => [qw(unused)],
                                                        }
                                              );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://unused/test.html!, 'Acceptable Domain');
}

# 10 - test an unacceptable domain in 'acceptable_domains' option 
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
                                                         acceptable_domains => [qw(acceptable.com)],
                                                        }
                                              );
    my $output = $mailpage->run();
    ok($output =~ m!not acceptable!, 'Domain Not Acceptable');
}

# 11 - test the 'extra_tmpl_params'
{
    $options->{format} = 'url';
    $options->{rm} = 'show_form';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         extra_tmpl_params => {
                                                            note => 'This is my note.',
                                                            },
                                                        }
                                              );
    my $output = $mailpage->run();
    ok($output =~ m!This is my note.!, 'extra_tmpl_params overrides');
}

# 12 - test the 'remote_fetch' with a bad url
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'both_attachment';
    $options->{page} = 'http://unused/test.html';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    ok($output =~ m!Unable to retrieve!i, 'remote_fetch invalid url');
}

# 13 - test the 'remote_fetch' with a good url with 'both_attachment'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'both_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://google\.com!, 'remote_fetch valid url (both_attachment)');
}

# 14 - test the 'remote_fetch' with a good url with 'html'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'html';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!<title>Google</title>!, 'remote_fetch valid url (html)');
}

# 15 - test the 'remote_fetch' with a good url with 'html_attachment'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'html_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!<title>Google</title>!, 'remote_fetch valid url (html)');
}

# 16 - test the 'remote_fetch' with a good url with 'text'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'text';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!Google!, 'remote_fetch valid url (html)');
}
                                                                                                                                           
# 17 - test the 'remote_fetch' with a good url with 'text_attachment'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'text_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!Google!, 'remote_fetch valid url (html)');
}

# 18 - test the 'remote_fetch' with a good url with 'url'
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'url';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
                                               QUERY => $query,
                                               PARAMS => {
                                                         document_root => './',
                                                         smtp_server => 'unused',
                                                         dump_mail => \$mail,
                                                         use_page_param => 1,
                                                         remote_fetch => 1,
                                                        }
                                              );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://google.com!, 'remote_fetch valid url (url)');
}


