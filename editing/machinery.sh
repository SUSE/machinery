# Copyright (c) 2013-2014 SUSE LLC
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


# machinery bash completion script

_machinery() {
  #========================================
  # Init completion
  #----------------------------------------
  local cur prev opts
  _get_comp_words_by_ref cur prev

  #========================================
  # Machinery paths
  #----------------------------------------
  local machinery_base=/usr/lib*/ruby/gems/*/gems/machinery*/
  local machinery_cmd=${machinery_base}lib/cli.rb
  local machinery_ins=${machinery_base}plugins/inspect

  #========================================
  # Current base command
  #----------------------------------------
  local cmd=$(echo $COMP_LINE | cut -f2 -d " " | tr - _)

  #========================================
  # Basic options to complete
  #----------------------------------------
  opts="--version --help"
  for name in $(cat $machinery_cmd |\
    grep "  desc " | cut -f2 -d \"| cut -f1 -d " "
  );do
    if [ "$name" = "global" ];then
      continue
    fi
    opts="$opts $name"
  done

  #========================================
  # Scopes to complete
  #----------------------------------------
  scopes=""
  for plugin in $machinery_ins/*;do
    local scope=$(basename $plugin)
    scope=$(echo $scope | sed -e "s@_inspector.rb@@")
    scopes="$scopes $scope"
  done

  #========================================
  # Descriptions to complete
  #----------------------------------------
  descriptions=""
  if [ -d ~/.machinery ];then
    for name in ~/.machinery/*;do
      if [ -d $name ];then
        descriptions="$descriptions $(basename $name)"
      fi
    done
  fi

  #========================================
  # Method specific options to complete
  #----------------------------------------
  opt_global="--verbose --debug"
  opt_analyze="$opt_global
    --operation
  "
  opt_inspect="$opt_global
    --scope --exclude-scope --name
    --extract-files --extract-changed-config-files
    --extract-unmanaged-files --extract-changed-managed-files --show
  "
  opt_build="$opt_global
    --image_dir --enable_dhcp --enable_ssh
  "
  opt_compare="$opt_global
    --scope --exclude-scope --show-all --no-pager
  "
  opt_deploy="$opt_global
    --cloud_config --image_dir --insecure --cloud_image_name
  "
  opt_export_kiwi="$opt_global
    --kiwi_dir --force
  "
  opt_remove="$opt_global
    --all
  "
  opt_show="$opt_global
    --scope --exclude-scope --no-pager --show-diffs
  "
  eval cmd_options=\$opt_$cmd
  if [ ! -z "$cmd_options" ];then
    opts=$cmd_options
  fi

  #========================================
  # Command option parameters completion
  #----------------------------------------
  case "${prev}" in
    analyze|deploy|remove|show|build|export-kiwi|copy|compare)
      comp_reply "$descriptions"
      warn_no_description
      return 0
    ;;
    list)
      comp_reply
      return 0
    ;;
    inspect)
      comp_reply "localhost"
      return 0
    ;;
    --scope|--exclude-scope)
      comp_reply "$scopes"
      return 0
    ;;
    *)
      local prev_prev="${COMP_WORDS[COMP_CWORD-2]}"
      case "$prev_prev" in
        compare|copy)
          comp_reply $descriptions
          warn_no_description
          return 0
        ;;
        *)
        ;;
      esac
    ;;
  esac
  #========================================
  # Command option completion
  #----------------------------------------
  comp_reply "$opts"
  return 0
}

#========================================
# warn_no_description
#----------------------------------------
function warn_no_description {
  if [ -z "$descriptions" ]; then
    echo -en "\n ==> no descriptions found\n$COMP_LINE"
  fi
}

#========================================
# comp_reply
#----------------------------------------
function comp_reply {
  word_list=$@
  COMPREPLY=($(compgen -W "$word_list" -- ${cur}))
}

complete -F _machinery machinery
