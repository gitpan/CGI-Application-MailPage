package CGI::Application::MailPage;

use strict;

use CGI::Application;
use File::Spec;
use HTML::Template;
use HTML::TreeBuilder;
use HTTP::Date;
use MIME::Entity;
use Mail::Header;
use Mail::Internet;
use Net::SMTP;
use Text::Format;

use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = qw(CGI::Application);

sub setup {
  my $self = shift;
  $self->start_mode('show_form');
  $self->mode_param('rm');
  $self->run_modes(
                   show_form => \&show_form,
                   send_mail => \&send_mail,
                  );

  # make sure we have required params
  die "You must set PARAMS => { document_root => '/path' } in your MailPage stub!"
    unless defined $self->param('document_root');

  die "You must set PARAMS => { smtp_server => 'your.smtp.server' } in your MailPage stub!"
    unless defined $self->param('smtp_server');
}

sub show_form {
  my $self = shift;
  my $alert = shift;
  my $query = $self->query;

  my $page = $query->param('page');
  if (not defined $page) {
    unless($self->param('use_page_param')) {
      $page = $query->referer();
      return "Sorry, I can't tell what page you want to send.  You need to be using either Netscape 4 or Internet Explorer 4 (or newer) to use this feature.  Please upgrade your browser and try again!"
        unless defined $page;
    } else {
      die "no value for page param!" unless defined $page;
    }
  }    

  my $template;
  if ($self->param('form_template')) {    
    $template = HTML::Template->new(filename => $self->param('form_template'),
                                    cache => 1, 
                                    associate => $query);
    
  } else {
    $template = HTML::Template->new(filename => 'CGI/Application/MailPage/form.tmpl',
                                    path => [@INC],
                                    cache => 1,
                                    associate => $query);
  }

  $template->param(PAGE => $page);
  $template->param(SUBJECT => $query->param('subject') || 
                   $self->param('email_subject') || 
                   '');

  $template->param(FORMAT_SELECTOR => 
                   $query->popup_menu(-name => 'format',
                                      '-values' => ['both_attachment', 'html','html_attachment', 'text', 'text_attachment', 'url'],
                                      -labels => {
                                                  url => 'Just A Link',
                                                  html => 'Full HTML',
                                                  html_attachment => 'Full HTML as an Attachment',
                                                  text => 'Plain Text',
                                                  text_attachment => 'Plain Text as an Attachment',
                                                  both_attachment => 'Both Text and Full HTML as Attachments',
                                                 },
                                      -default => 'both_attachment',
                                     ));
  
  $template->param(ALERT => $alert) if defined $alert;
  return $template->output();
}

sub send_mail {
  my $self = shift;
  my $query = $self->query;

  # check parameters
  my $name = $query->param('name');
  die "Missing parameter assignment for \$name!"
    unless defined($name);

  my $from_email = $query->param('from_email');
  die "Missing parameter assignment for \$from_email!"
    unless defined($from_email);  
  
  my $to_emails = $query->param('to_emails');
  die "Missing parameter assignment for \$to_emails!"
    unless defined($to_emails);

  my $note = $query->param('note');
  die "Missing parameter assignment for \$note!"
    unless defined($note);
  
  my $format = $query->param('format');
  die "Missing parameter assignment for \$format!"
    unless defined($format);

  my $subject = $query->param('subject');
  die "Missing parameter assignment for \$subject!"
    unless defined($subject);  
    
  my $page = $query->param('page');
  die "Missing parameter assignment for \$page!"
    unless defined($page);
  
  return $self->show_form("Please fill in your name in the form below.")
    unless length $name;

  return $self->show_form("Please fill in your email address in the form below.")
    unless length $from_email;

  return $self->show_form("Please fill in your friends' email addresses in the form below.")
    unless length $to_emails;

  return $self->show_form("Please enter a Subject for the email in the form below.")
    unless length $subject;

  # check from_email
  return $self->show_form("Your email address is invalid - it should look like name\@host.com.")
    unless $from_email =~ /^[-\w\.]+\@[-\w\.]+$/;

  # parse out to_emails
  my @to_emails;
  foreach (split(/[\s,]+/, $to_emails)) {
    next unless length $_;
    return $self->show_form("One of your friend's email addresses is invalid - \"$_\" - it should look like name\@host.com.")
      unless /^[-\w\.]+\@[-\w\.]+$/;
    push(@to_emails, $_);
  }
  return $self->show_form("Please fill in your friends' email addresses in the form below.")
    unless @to_emails;

  # find the HTML file to open
  my $filename = $self->_find_html_file($page);
  die "Unable to find file $filename for page $page (might be empty or unreadable): $!"
    unless -e $filename and -r _ and -s _;
  my ($vol, $dir, $file) = File::Spec->splitpath($filename);

  my $base_url = $page;
  $base_url =~ s/\Q$file\E//;
 
  # if file is empty, assume index.html
  if (not defined $file or not length $file) {
    $file = 'index.html';
    $filename .= '/index.html';
  }
 
  my ($base, $ext) = $file =~ /(.*)\.([^\.]+)$/;

  # open the email template
  my $template;
  if ($self->param('email_template')) {    
    $template = HTML::Template->new(filename => $self->param('email_template'),
                                    associate => $query,
                                    cache => 1);
    
  } else {
    $template = HTML::Template->new(filename => 'CGI/Application/MailPage/email.tmpl',
                                    associate => $query,
                                    path => \@INC,
                                    cache => 1);
  }

  # $msg will end up with either a Mail::Internet or MIME::Entity
  # object.
  my $msg;

  # are we doing attachments?
  if (index($format, '_attachment') != -1) {
    # open up a MIME::Entity for our msg
    $msg = MIME::Entity->build(
                               Type     => "multipart/mixed",
                               From     => "$name <$from_email>",
                               'Reply-To' => "$name <$from_email>",
                               To       => \@to_emails,
                               Subject  => $subject,
                               Date => HTTP::Date::time2str(time()),
                              );

    $msg->attach(Data => $template->output);

    # attach the straight HTML if requested
    if ($format =~ /^(both|html)/) {
      my $buffer = "";
      if ($self->param('read_file_callback')) {
        my $callback = $self->param('read_file_callback');
        $buffer = $callback->($filename);
      } else {
        open(HTML, $filename) or die "Can't open $filename : $!";
        while(read(HTML, $buffer, 10240, length($buffer))) {}      
        close(HTML);
      }
       
      # add <BASE> tag in <HEAD>
      $buffer =~ s/(<\s*[Hh][Ee][Aa][Dd].*?>)/$1\n<base href=$base_url>\n/;
      
      $msg->attach(Data => $buffer,
                   Type => 'text/html',
                   Filename => $base . '.html',
                  );
    }

    # attach text translation
    if ($format =~ /^(both|text)/) {
      $msg->attach(Data => $self->_html2text($filename),
                   Type => 'text/plain',
                   Filename => $base . '.txt',
                  );
    }

  } else {
    # non attachment mail
    my $header = Mail::Header->new();
    $header->add(From => "$name <$from_email>");
    $header->add('Reply-To' => "$name <$from_email>");
    $header->add(To => join(', ', @to_emails));
    $header->add(Subject  => $subject);
    $header->add(Date => HTTP::Date::time2str(time()));

    my @lines;
    push(@lines, $template->output());

    if ($format =~ /^(both|text)/) {
      push(@lines, "\n---\n\n");
      push(@lines, $self->_html2text($filename));
    }
    
    if ($format =~ /^(both|html)/) {
      push(@lines, "\n---\n\n");
      if ($self->param('read_file_callback')) {
        my $callback = $self->param('read_file_callback');
        my $buffer = $callback->($filename);
        push(@lines, split("\n", $buffer));
      } else {
        open(HTML, $filename) or die "Can't open $filename : $!";
        push(@lines, <HTML>);
        close(HTML);
      }
    }

    if ($format =~ /url/) {
      push(@lines, "\n$page");
    }

    $msg = Mail::Internet->new([], Header => $header, Body => \@lines);
    die "Unable to create Mail::Internet object!"
      unless defined $msg;
  }
    
  # send the message using SMTP - other methods can be added later
  unless($self->param('dump_mail')) {
    my $smtp = Net::SMTP->new($self->param('smtp_server'));
    die "Unable to connect to SMTP server ".$self->param('smtp_server')." : $!"
      unless defined $smtp and UNIVERSAL::isa($smtp,'Net::SMTP');
    $smtp->debug(1) if $self->param('smtp_debug');
  
    $smtp->mail("$name <$from_email>");
    foreach (@to_emails) {
      $smtp->to($_);
    }
    $smtp->data();
    $smtp->datasend($msg->as_string());
    $smtp->dataend();
    $smtp->quit();

  } else {
    # debuging hook for test.pl
    my $mailref = $self->param('dump_mail');
    $$mailref = $msg->as_string();
    die "Mail Dumped";
  }   

  # all done
  return $self->show_thanks;
}

sub show_thanks {
  my $self = shift;
  my $query = $self->query;
  my $page = $query->param('page');

  my $template;
  if ($self->param('thanks_template')) {    
    $template = HTML::Template->new(filename => $self->param('thanks_template'),
                                    cache => 1);
    
  } else {
    $template = HTML::Template->new(filename => 'CGI/Application/MailPage/thanks.tmpl',
                                    path => [@INC],
                                    cache => 1);
  }

  $template->param(PAGE => $page);
  return $template->output();
}


sub _find_html_file {
  my $self = shift;
  my $url = shift;
  
  # if it doesn't start with http, its invalid
  die "Invalid page url: $url"
    unless $url =~ m!^https?://([-\w\.]+)/(.*)!;
  
  my $host = $1;
  my $path = $2;
  
  # if the path starts with a ~user thing, remove it
  $path =~ s!~[^/]+/!!;
  
  # append it to document_root and return it
  return File::Spec->join($self->param('document_root'), $path);
}  
    
# takes an html file and returns text.  This code was taken and
# modified from html2text.pl by Ave Wrigley.  I don't really
# understand most of it, but it seems to work well.

#--------------------------------------------------------------------------
#
# prefixes to convert tags into - some are converted bachk to Text::Format
# formatting later
#
#--------------------------------------------------------------------------

my %prefix = (
              'li'        => '* ',
              'dt'        => '+ ',
              'dd'        => '- ',
             );

my %underline = (
                 'h1'        => '=',
                 'h2'        => '-',
                 'h3'        => '-',
                 'h4'        => '-',
                 'h5'        => '-',
                 'h6'        => '-',
                );

my @heading_number = ( 0, 0, 0, 0, 0, 0 );

sub _html2text {
  my $self = shift;
  my $filename = shift;

  my $html_tree = new HTML::TreeBuilder;
  my $text_formatter = new Text::Format;
  $text_formatter->firstIndent( 0 );

  my $result = "";

  #----------------------------------------------------------------------
  #
  # get_text - get all the text under a node
  #
  #----------------------------------------------------------------------

  sub get_text
    {
      my $this = shift;
      my $text = '';
      
      # iterate though my children ...
      return unless defined $this->content;
      for my $child ( @{ $this->content } )
        {
          # if the child is also non-text ...
          if ( ref( $child ) )
            {
              # traverse it ...
              $child->traverse(
                               # traveral callback
                               sub {
                                 my( $node, $startflag, $depth ) = @_;
                                 # only visit once
                                 return 0 unless $startflag;
                                 # if it is non-text ...
                                 if ( ref( $node ) )
                                   {
                                     # recurse get_text
                                     $text .= get_text( $node );
                                   }
                                 # if it is text
                                 else
                                   {
                                     # add it to $text
                                     $text .= $node if $node =~ /\S/;
                                   }
                                 return 0;
                               },
                               0
                              );
            }
          # if it is text
          else
            {
              # add it to $text
              $text .= $child if $child =~ /\S/;
            }
        }
      return $text;
    }
  
  #--------------------------------------------------------------------------
  #
  # get_paragraphs - routine for generating an array of paras from a given node
  #
  #--------------------------------------------------------------------------
  
  sub get_paragraphs
    {
      my $this = shift;
      
      # array to save paragraphs in
      my @paras = ();
      # avoid -w warning for .= operation on undefined
      $paras[ 0 ] = '';
      
      # iterate though my children ...
      for my $child ( @{ $this->content } )
        {
          # if the child is also non-text ...
          if ( ref( $child ) )
            {
              # traverse it ...
              $child->traverse(
                               # traveral callback
                               sub {
                                 my( $node, $startflag, $depth ) = @_;
                                 # only visit once
                                 return 0 unless $startflag;
                                 # if it is non-text ...
                                 if ( ref( $node ) )
                                   {
                                     # if it is a list element ...
                                     if ( $node->tag =~ /^(?:li|dd|dt)$/ )
                                       {
                                         # recurse get_paragraphs
                                         my @new_paras = get_paragraphs( $node );
                                         # pre-pend appropriate prefix for list
                                         $new_paras[ 0 ] =
                                           $prefix{ $node->tag } . $new_paras[ 0 ]
                                             ;
                                         # and update the @paras array
                                         @paras = ( @paras, @new_paras );
                            # and traverse no more
                                         return 0;
                                       }
                                     else
                                       {
                                         # any other element, just traverse
                                         return 1;
                                       }
                                   }
                                 else
                                   {
                                     # add text to the current paragraph ...
                                     $paras[ $#paras ] = 
                                       join( ' ', $paras[ $#paras ], $node )
                                         if $node =~ /\S/
                                           ;
                                     # and recurse no more
                                     return 0;
                                   }
                               },
                               0
                              );
            }
          else
            {
              # add test to current paragraph ...
              $paras[ $#paras ] = join( ' ', $paras[ $#paras ], $child )
                if $child =~ /\S/
                  ;
            }
        }
      return @paras;
    }
  
  #--------------------------------------------------------------------------
  #
  # Main
  #
  #--------------------------------------------------------------------------
  
  # parse the HTML file
  if ($self->param('read_file_callback')) {
    my $callback = $self->param('read_file_callback');
    $html_tree->parse( $callback->($filename) );
  } else {
    open(HTML, $filename) or die "Can't open $filename : $!";
    $html_tree->parse( join( '', <HTML> ) );
    close(HTML);
  }

  # main tree traversal routine
  
  $html_tree->traverse(
                       sub {
                         my( $node, $startflag, $depth ) = @_;
                         # ignore what's in the <HEAD>
                         return 0 if ref( $node ) and $node->tag eq 'head';
                         # only visit nodes once
                         return 0 unless $startflag;
                         # if this node is non-text ...
                         if ( ref $node )
                           {
                             # if this is a para  ...
                             if ( $node->tag eq 'p' )
                               {
                                 # iterate sub-paragraphs (including lists) ...
                                 for ( get_paragraphs( $node ) )
                                   {
                                     # if it is a <LI> ...
                                     if ( /^\* / )
                                       {
                                         # indent first line by 4, rest by 6
                                         $text_formatter->firstIndent( 4 );
                                         $text_formatter->bodyIndent( 6 );
                                       }
                                     # if it is a <DT> ...
                                     elsif ( s/^\+ // )
                                       {
                                         # set left margin to 4
                                         $text_formatter->leftMargin( 4 );
                                       }
                                     # if it is a <DD> ...
                                     elsif ( s/^- // )
                                       {
                                         # set left margin to 8
                                         $text_formatter->leftMargin( 8 );
                                       }
                                     # print formatted paragraphs ...
                                     $result .= $text_formatter->paragraphs( $_ );
                                     # and reset formatter defaults
                                     $text_formatter->leftMargin( 0 );
                                     $text_formatter->firstIndent( 0 );
                                     $text_formatter->bodyIndent( 0 );
                                   }
                                 $result .= "\n";
                                 return 0;
                               }
                             # if this is a heading ...
                             elsif ( $node->tag =~ /^h(\d)/ )
                               {
                                 # get the heading level ...
                                 my $level = $1;
                                 # increment the number for this level ...
                                 $heading_number[ $level ]++;
                                 # reset lower level heading numbers ...
                                 for ( $level+1 .. $#heading_number )
                                   {
                                     $heading_number[ $_ ] = 0;
                                   }
                                 # create heading number string
                                 my $heading_number = join( 
                                                           '.', 
                                                           @heading_number[ 1 .. $level ]
                                                          );
                                 # generate heading from number string and heading text ...
                                 # my $text = "$heading_number " . get_text( $node );
                                 my $text = get_text( $node );
                                 # underline it with the appropriate underline character ...
                                 $text =~ s{
                        (.*)
                    }
                                   {
                                     "$1\n" . $underline{ $node->tag } x length( $1 )
                                   }gex
                                     ;
                                 $result .= $text;
                                 return 0;
                               } else {
                                 return 1;
                               }
                           }
                         # if it is text ...
                         else
                           {
                             return 0 unless $node =~ /\S/;
                             $result .= $text_formatter->format( $node );
                             return 0;
                           }
                       },
                       0
                      );

  # filter out comments
  $result =~ s/<!--.*?-->//gs;

  return $result;
}  
  

1;
__END__

=head1 NAME

CGI::Application::MailPage - module to allow users to send HTML pages to friends.

=head1 SYNOPSIS

   use CGI::Application::MailPage;
   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org' });
   $mailpage->run();

=head1 DESCRIPTION

CGI::Application::MailPage is a CGI::Application module that allows
users to send HTML pages to their friends.  This module provides the
functionality behind a typical "Mail This Page To A Friend" link.

To use this module you need to create a simple "stub" script.  It
should look like:

   #!/usr/bin/perl
   use CGI::Application::MailPage;
   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { 
                              document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org',
                            },
                );
   $mailpage->run();

You'll need to replace the "/home/httpd" with the real path to your
document root - the place where the HTML files are kept for your site.
You'll also need to change "smtp.foo.org" to your SMTP server.

Put this somewhere where CGIs can run and name it something like
C<mailpage.cgi>.  Now, add a link in the pages you want people to be
able to send to their friends that looks like:

   <A HREF="mailpage.cgi">mail this page to a friend</A>

This gets you the default behavior and look.  To get something more to
your specifications you can use the options described below.

=head1 OPTIONS

CGI::Application modules accept options using the PARAMS arguement to
C<new()>.  To give options for this module you change the C<new()>
call in the "stub" shown above:

   my $mailpage = CGI::Application::MailPage->new(
                      PARAMS => {
                                  document_root => '/home/httpd',
                                  smtp_server => 'smtp.foo.org',
                                  use_page_param => 1,
                                }
                   );

The C<use_page_param> option tells MailPage not to use the REFERER
header to determine the page to mail.  See below for more information
about C<use_page_param> and other options.

=over 4

=item * document_root (required)

This parameter is used to specify the document root for your server -
this is the place where the HTML files are kept.  MailPage needs to
know this so that it can find the HTML files to email.

=item * smtp_server (required)

This must be set to an SMTP server that MailPage can use to send mail.
Future versions of MailPage may support other methods of sending mail,
but for now you'll need a working SMTP server.

=item * use_page_param

By default MailPage uses the REFERER header to determine the page that
the user wants to mail to their friends.  This doesn't always work
right, particularily on very old browsers.  If you don't want to use
REFERER then you can set this option and write your links to the
application as:

   <A HREF="mailpage.cgi?page=http://host/page.html">mail page</A>

You'll have to replace http://host/page.html with the url for each
page you put the link in.  You could cook up some Javascript to do
this for you, but if the browser has working Javascript then it
probably has a working REFERER!

=item * email_subject

The default subject of the email sent from the program.  Defaults to
empty, requiring the user to enter a subject.

=item * form_template

This application uses HTML::Template to generate its HTML pages.  If
you would like to customize the HTML you can copy the default form
template and edit it to suite your needs.  The default form template
is called 'form.tmpl' and you can get it from the distribution or from
wherever this module ended up in your C<@INC>.  Pass in the path to
your custom template as the value of this parameter.

See L<HTML::Template|HTML::Template> for more information about the
template syntax.

=item * thanks_template

The default "Thanks" page template is called 'thanks.tmpl' and you can
get it from the distribution or from wherever this module ended up in
your C<@INC>.  Pass in the path to your custom template as the value
of this parameter.

See L<HTML::Template> for more information about the template syntax.

=item * email_template

The default email template is called 'email.tmpl' and you can get it
from the distribution or from wherever this module ended up in your
C<@INC>.  Pass in the path to your custom template as the value of
this parameter.

See L<HTML::Template> for more information about the template syntax.

=item * read_file_callback

You can provide a subroutine reference that will be called when
MailPage needs to open an HTML file on your site.  This can used to
resolve complex aliasing problems or to perform any desired
manipulation of the HTML text.  The called subroutine recieves one
arguement, the name of the file to be opened.  It should return the
text of the file.  Here's an example that changes all 'p's to 'q's in
the text of the files:

   #!/usr/bin/perl -w
   use CGI::Application::MailPage;

   sub p_to_q {
     my $filename = shift;
     open(FILE, $filename) or die;

     my $buffer;
     while(<FILE>) {
       s/p/q/g;
       $buffer .= $_;
     }
    
     return $buffer;
   }

   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { 
                              document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org',
                              read_file_callback => \&p_to_q,
                            },
                );
   $mailpage->run();
       

=head1 AUTHOR

Copyright 2002, Sam Tregar (sam@tregar.com).

Questions, bug reports and suggestions can be sent to the
CGI::Application mailing list.  You can subscribe by sending a blank
message to cgiapp-subscribe@lists.vm.com.  See you there!

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Application|CGI::Application>, L<HTML::Template|HTML::Template>

=cut
