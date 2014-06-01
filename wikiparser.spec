Summary: WikiParser
Name: wikiparser
Version: 0.0.8
Release: 1%{?dist}
License: BSD License
Group: Development/Tools/Other
Packager: Mark Wharton <mark@jynx.com>
URL: http://www.kinoma.com/wikiparser/
%description
WikiParser for Amazon Linux AMI.

%define _missing_doc_files_terminate_build 0
%define _unpackaged_files_terminate_build 0

%build
# F_HOME=/home/ec2-user/fsk rpmbuild -bb wikiparser.spec
cd $F_HOME/kinoma/simpleWebService/libraries/wiki
./configure --prefix=/usr --libdir=/usr/lib64
make

%install
make -C $F_HOME/kinoma/simpleWebService/libraries/wiki DESTDIR=$RPM_BUILD_ROOT install

%files
%attr(0644,root,root) /usr/include/wikiparser.h
%attr(0644,root,root) /usr/lib64/libwikiparser.a
%attr(0644,root,root) /usr/lib64/libwikiparser.so
%attr(0644,root,root) /usr/lib64/libwikiparser.so.1
%attr(0644,root,root) /usr/lib64/libwikiparser.so.1.1.0

%changelog
* Thu May 29 2014 Mark Wharton <mark@jynx.com> - 0.0.8-1
- Capture additional closing characters for inline nowiki, placeholder, and plugin
* Sat Dec 07 2013 Mark Wharton <mark@jynx.com> - 0.0.7-1
- First build for Amazon Linux AMI
