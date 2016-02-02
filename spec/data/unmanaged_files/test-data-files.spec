#
# spec file for package test-data-files
#
# Copyright (c) 2013-2016 SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

Name:		test-data-files
Version:	1.0
Release:	1
BuildArch:	noarch
License:	GPL-3.0
Summary:	A test package what contains several files for testing Machinery
Group:		Development
BuildRoot:      %{_tmppath}/%{name}-%{version}-build



%description
A test package what contains several files for testing Machinery.

%prep
mkdir -p %{buildroot}"/opt/test-quote-char/test-dir-name-with-' quote-char '"
touch %{buildroot}"/opt/test-quote-char/test-dir-name-with-' quote-char '/test-file-name-with-' quote-char '"
touch %{buildroot}"/opt/test-quote-char/link"
touch %{buildroot}"/opt/test-quote-char/target-with-quote'-foo"
mkdir -p %{buildroot}"/etc"
mkdir -p %{buildroot}"/usr/bin"
LC_ALL=en_US.utf8
mkdir -p %{buildroot}"/etc"
echo "# umlaut conf" > %{buildroot}"/etc/umlaut-äöü.conf"
mkdir -p %{buildroot}"/usr/bin"
echo "#!/bin/bash\necho umlaut" > %{buildroot}"/usr/bin/umlaut-äöü"
mkdir -p %{buildroot}"/etc/stat-test"
touch %{buildroot}"/etc/stat-test/test.conf"

%files
%defattr(-,root,root)
/opt/test-quote-char
/usr/bin/umlaut-*
%config /etc/umlaut*.conf
%attr(600,root,root) /etc/stat-test
%config /etc/stat-test/test.conf

%changelog
