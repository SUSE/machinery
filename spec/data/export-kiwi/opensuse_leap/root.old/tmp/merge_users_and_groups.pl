#!/usr/bin/env perl

# Copyright (c) 2013-2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

use strict;
use warnings;
use FileHandle;

my $local_passwd_path = shift;
my $local_shadow_path = shift;
my $local_group_path = shift;


my $fh = FileHandle->new;
my @existing_passwd_entries = [];
if($fh->open("< $local_passwd_path")) {
  @existing_passwd_entries = <$fh>;
  $fh->close;
}
my @existing_shadow_entries = [];
if($fh->open("< $local_shadow_path")) {
  @existing_shadow_entries = <$fh>;
  $fh->close;
}
my @existing_group_entries = [];
if($fh->open("< $local_group_path")) {
  @existing_group_entries = <$fh>;
  $fh->close;
}

# This array contains arrays of the new passwd and shadow entries, e.g.
# (
#   ["svn:x:482:476:user for Apache Subversion svnserve:/srv/svn:/sbin/nologin", "svn:!:16058::::::"],
#   ["nscd:x:484:478:User for nscd:/var/run/nscd:/sbin/nologin", "nscd:!:16058::::::"]
# )
my @new_passwd_entries = (
['+::::::', '+::::::::'],
['bin:x:1:1:bin:/bin:/bin/bash', 'bin:*:16758::::::'],
['daemon:x:2:2:Daemon:/sbin:/bin/bash', 'daemon:*:16758::::::'],
['ftp:x:40:49:FTP account:/srv/ftp:/bin/bash', 'ftp:*:16758::::::'],
['games:x:12:100:Games account:/var/games:/bin/bash', 'games:*:16758::::::'],
['lp:x:4:7:Printing daemon:/var/spool/lpd:/bin/bash', 'lp:*:16758::::::'],
['machinery:x:1001:100::/home/machinery:/bin/bash', 'machinery:$6$tduZwKgK$06gFeFM2P0TrSAaRlcEIA9IPYdCrhMoQgqu6UJ6espsYf9lOpoLZyCWY7VLk8zrZjV1rMZqWgOw0iiHpmUFuc.:16758:0:99999:7:::'],
['mail:x:8:12:Mailer daemon:/var/spool/clientmqueue:/bin/false', 'mail:*:16758::::::'],
['man:x:13:62:Manual pages viewer:/var/cache/man:/bin/bash', 'man:*:16758::::::'],
['messagebus:x:499:497:User for D-Bus:/var/run/dbus:/bin/false', 'messagebus:!:16758::::::'],
['news:x:9:13:News system:/etc/news:/bin/bash', 'news:*:16758::::::'],
['nobody:x:65534:65533:nobody:/var/lib/nobody:/bin/bash', 'nobody:*:16758::::::'],
['polkitd:x:495:495:User for polkitd:/var/lib/polkit:/sbin/nologin', 'polkitd:!:16758::::::'],
['root:x:0:0:root:/root:/bin/bash', 'root:lt3Uy3nl9aYpU:16758::::::'],
['rpc:x:498:65534:user for rpcbind:/var/lib/empty:/sbin/nologin', 'rpc:!:16758::::::'],
['sshd:x:497:496:SSH daemon:/var/lib/sshd:/bin/false', 'sshd:!:16758::::::'],
['statd:x:496:65534:NFS statd daemon:/var/lib/nfs:/sbin/nologin', 'statd:!:16758::::::'],
['uucp:x:10:14:Unix-to-Unix CoPy system:/etc/uucp:/bin/bash', 'uucp:*:16758::::::'],
['vagrant:x:1000:1000::/home/vagrant:/bin/bash', 'vagrant:lt3Uy3nl9aYpU:16758:0:99999:7:::'],
['wwwrun:x:30:8:WWW daemon apache:/var/lib/wwwrun:/bin/false', 'wwwrun:*:16758::::::']
);

# This array contains the new group entries, e.g.:
# (
#   "ntp:x:102:",
#   "at:x:103:"
# )
my @new_group_entries = (
'+:::',
'audio:x:17:',
'bin:x:1:daemon',
'cdrom:x:20:',
'console:x:21:',
'daemon:x:2:',
'dialout:x:16:',
'disk:x:6:',
'floppy:x:19:',
'ftp:x:49:',
'games:x:40:',
'kmem:x:9:',
'lock:x:54:',
'lp:x:7:',
'mail:x:12:',
'man:x:62:',
'messagebus:x:497:',
'modem:x:43:',
'news:x:13:',
'nobody:x:65533:',
'nogroup:x:65534:nobody',
'polkitd:x:495:',
'public:x:32:',
'root:x:0:',
'shadow:x:15:',
'sshd:x:496:',
'sys:x:3:',
'systemd-journal:x:499:',
'tape:x:498:',
'trusted:x:42:',
'tty:x:5:',
'users:x:100:',
'utmp:x:22:',
'uucp:x:14:',
'vagrant:x:1000:',
'video:x:33:',
'wheel:x:10:',
'www:x:8:',
'xok:x:41:'
);

# Takes a passwd entry as the argument and replaces the uid with an id that is
# not already used in the existing passwd file
sub fix_ids {
  my $passwd_entry = shift;
  my @fields = split(/:/x, $passwd_entry);
  my $uid = $fields[2];
  my $gid = $fields[3];

  while(grep { /^[^:]*:[^:]*:$uid:/x } @existing_passwd_entries) {
    $uid = $uid + 1;
  }

  $passwd_entry =~ s/^([^:]*:[^:]*):\d+:/$1:$uid:/x;

  return $passwd_entry;
}

# Takes a group entry as the argument and replaces the uid with an id that is
# not already used in the existing group file
sub fix_group_id {
  my $group = shift;
  my @fields = split(/:/x, $group);
  my $original_gid = $fields[2];
  my $gid = $original_gid;

  while(grep { /^[^:]*:[^:]*:$gid:/x } @existing_group_entries) {
    $gid = $gid + 1;
  }
  $group =~ s/^([^:]*:[^:]*):$original_gid:/$1:$gid:/x;

  # Also update the gid in the list of new passwd entries
  foreach my $entry_ref (@new_passwd_entries) {
    $entry_ref->[0] =~ s/^([^:]*:[^:]*:[^:]*):$original_gid:/$1:$gid:/x;
  }

  return $group;
}

# Takes two comma-separated lists and merges them. Duplicates are removed.
sub merge_group_users {
  my $a = $_[0] // "";
  my $b = $_[1] // "";
  chomp($a);
  chomp($b);
  my @users = (split(",", $a), split(",", $b));

  #remove duplicate entries
  my %hash = ();
  foreach my $item (@users) {
    $hash{$item} = '';
  }
  @users = sort keys %hash;

  return join(",", @users);
}

# Iterate over the new group entries and fix ids where necessary.
#
# If the group already exists on the system the group is not added again, but the
# new passwd entries that reference this group are adjusted to the other gid.
#
# If the group does not exist yet, the group is appended to /etc/group. If
# necessary, the gid will be adjusted to not conflict with the existing ones.
my %gid_changes = ();
foreach my $entry (@new_group_entries) {
  my @fields = split(/:/x, $entry);
  my $id = $fields[0];
  my $gid = $fields[2];

  my @match = grep { /^$id:.*/x } @existing_group_entries;
  if(scalar @match > 0) {
    print "Group match: $match[0]\n";

    my @original_fields = split(/:/x, $match[0]);
    my $original_gid = $original_fields[2];

    # Store all gid transformations in the %gid_changes hash
    $gid_changes{$gid} = $original_gid;


    # Update existing entry with the new attributes
    $fields[2] = $original_gid;
    my $users = merge_group_users($original_fields[3], $fields[3]);
    $entry =~ s/^([^:]*:[^:]*):.*/$1:$original_gid:$users/x;
    foreach my $group_ref (@existing_group_entries) {
      $group_ref =~ s/\Q$match[0]\E/$entry/x;
    }
  } else {
    print "No match for group ", $id, " (", $entry,")\n";

    my $fixed_entry = fix_group_id($entry);
    print "  -> Writing: ", $fixed_entry, "\n";

    push(@existing_group_entries, $fixed_entry);
  }
}

# Apply all gid transformations to the list of new passwd entries
foreach my $entry_ref (@new_passwd_entries) {
  my @fields = split(/:/x, $entry_ref->[0]);
  my $gid = $fields[3];

  if($gid_changes{$gid}) {
    $entry_ref->[0] =~ s/^([^:]*:[^:]*:[^:]*):$gid:/$1:$gid_changes{$gid}:/x;
  }
}

# Iterate over the new passwd and shadow entries and fix ids where necessary.
#
# If the user already exists on the system the existing uid/gid is reused.
#
# If the user does not exist yet it is appended to /etc/passwd and /etc/shadow
# with a uid that does not conflict.
foreach my $entry (@new_passwd_entries) {
  my @fields = split(/:/x, @$entry[0]);
  my $id = $fields[0];

  my @match = grep { /^$id:.*/x } @existing_passwd_entries;
  if(scalar @match > 0) {
    my @original_fields = split(/:/x, $match[0]);
    my $uid = $original_fields[2];

    $fields[2] = $uid;
    my $new_entry = join(":", @fields);

    foreach my $passwd_ref (@existing_passwd_entries) {
      $passwd_ref =~ s/\Q$match[0]\E/$new_entry/x;
    }
    if(@$entry[1]) {
      foreach my $shadow_ref (@existing_shadow_entries) {
        $shadow_ref =~ s/^$id.*/@$entry[1]/x;
      }
    }
  } else {
    print "No match for user $id (@$entry[0])\n";

    my $fixed_entry = fix_ids(@$entry[0]);
    print "  ->Writing: ", $fixed_entry, "\n";

    push(@existing_passwd_entries, $fixed_entry);
    if(@$entry[1]) {
      push(@existing_shadow_entries, @$entry[1]);
    }
  }
}

# Write final lists to files
if($fh->open("> $local_passwd_path")) {
  foreach(@existing_passwd_entries) {
    chomp;
    $fh->print("$_\n");
  }
  $fh->close;
}
if($fh->open("> $local_shadow_path")) {
  foreach(@existing_shadow_entries) {
    chomp;
    $fh->print("$_\n");
  }
  $fh->close;
}
if($fh->open("> $local_group_path")) {
  foreach(@existing_group_entries) {
    chomp;
    $fh->print("$_\n");
  }
  $fh->close;
}
