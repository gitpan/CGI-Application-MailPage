use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'CGI::Application::MailPage',
              'VERSION_FROM' => 'MailPage.pm',
              'PREREQ_PM' => {
                              'File::Spec' => 0,
                              'HTML::Template' => 0,
                              'HTML::TreeBuilder' => 0,
                              'HTTP::Date' => 0,
                              'MIME::Entity' => 0,
                              'Mail::Header' => 0,
                              'Mail::Internet' => 0,
                              'Net::SMTP' => 0,
                              'Text::Format' => 0,
                              'CGI::Application' => 0,
                             },
              'PM' => {
                       'MailPage.pm' => '$(INST_LIBDIR)/MailPage.pm',
                       'email.tmpl' => '$(INST_LIBDIR)/MailPage/email.tmpl',
                       'form.tmpl' => '$(INST_LIBDIR)/MailPage/form.tmpl',
                       'thanks.tmpl' => '$(INST_LIBDIR)/MailPage/thanks.tmpl',
                      },
               );


