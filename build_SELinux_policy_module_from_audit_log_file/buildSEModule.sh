#!/bin/bash
#
# written by Bekcpear <i@ume.ink>
#
# generate selinux policy module from audit log file, and reserve the .te files
# you can also keep the corresponding log files
# compatible with Gentoo and CentOS 7
#

sedir=''
tedir=''
moddir=''
ppdir=''

logfile=''
modname=''
defaultlog=0
overridedF=0

defaultsedir='./.selinux_module_gen_dir'
function overjudge() {
  if [ -e "$1" ]; then
    if [ -f "$1" ]; then
      if [ $overridedF -eq 0 ];then
        local overflag=''
        echo -n "[NOTICE] override existed file $1? [y/N]: "
        read -n 1 -er overflag
        if [ "${overflag}x" != yx ]; then
          echo "not overrided. exit.."
          exit 1
        fi
      fi
    else
      echo "[ERROR]  $1 existed and is not a regular file."
      exit 1
    fi
  fi
}

function predir(){
  if [ ! -e "$1" ]; then
    eval "mkdir -p '$1'"
    echo "[NOTICE] created directory $1"
  elif [ ! -d "$1" ]; then
    echo "[ERROR]  $1 existed but is not a directory."
    exit 1
  elif [ ! -w "$1" ]; then
    echo "[ERROR]  no write permission under $1"
    exit 1
  fi
}

function showhelp() {
  echo
  echo "  Usage: $0 [OPTIONS] [MODULENAME]"
  echo
  echo '    the default module name is "fixse<date><sequence>", e.g.: fixse2017081501'
  echo
  echo '    -i <file>        audit log file'
  echo '                     (default read all from audit, message and dmesg logs since last policy reload)'
  echo "    -d <dir>         main directory of this script [dir] (default $defaultsedir)"
  echo '    -t <dir>         .te file directory (default [dir]/te)'
  echo '    -m <dir>         .mod file directory (default [dir]/mod)'
  echo '    -o <dir>         the generated .pp file directory (default [dir]/pp)'
  echo '    -f               force to override existed files'
  echo
  echo '    -h               print this help'
  echo
}

if [[ $- =~ .*i.* ]]; then
  echo -n '[NOTICE] This script is executed under an interactive shell, continue to execute may result an unexpected exit of current interactive shell, continue? [y/N]: '
  read -n 1 -er cont
  if [ "${cont}x" == yx ]; then
    echo 'continue..'
  else
    echo 'exit..'
    exit 1
  fi
fi

if [[ $0 =~ ^(.*/.+/)?bash$ ]]; then
  shift
fi

create_default_flag_file=0
if [[ $@ == '' ]]; then
  if [ ! -f "$defaultsedir/.default_flag" ]; then
    echo '[NOTICE] This script is executed without options and module name.'
    echo "[NOTICE] if you choice continue, this script will create a cache file under the default $defaultsedir directory. so you will not see this notification again, and the default action will be set [continue] for convenience."
    echo 'Continue to execute with default settings?'
    while true; do
      echo -n 'continue defaults[c]  help[h]  exit[q]: '
      read -n 1 -er defaultact
      case ${defaultact} in
        c)
          create_default_flag_file=1
          break
          ;;
        h)
          showhelp
          ;;
        q)
          exit 0
          ;;
        ?)
          ;;
      esac
    done
  fi
fi

modname_setted=0
function setmodname() {
  modname="${1}"
  modname_setted=1
}
while [[ ! ${1} =~ ^- && ${1} != '' ]]; do
  if [ ${modname_setted} -eq 0 ];then
    setmodname "${1}"
    shift
  fi
done

while getopts ":i:d:t:m:o:fh" doopt;
do
  case ${doopt} in
    i)
      logfile="${OPTARG}"
      ;;
    d)
      sedir="${OPTARG%%/}"
      ;;
    t)
      tedir="${OPTARG%%/}"
      ;;
    m)
      moddir="${OPTARG%%/}"
      ;;
    o)
      ppdir="${OPTARG%%/}"
      ;;
    f)
      overridedF=1
      ;;
    h)
      showhelp
      exit 0
      ;;
    ?)
      ;;
  esac
done

shift $((${OPTIND} - 1))
if [ "${1}x" != x ]; then
  if [ ${modname_setted} -eq 0 ];then
    setmodname "${1}"
  else
    echo '[ERROR]  redundant module settings'
    showhelp
    exit 1
  fi
fi

allmodules=$(semodule -lfull)
errorcode=$?
if [ $errorcode -ne 0 ]; then
  exit $errorcode
fi

if [ "${modname}"x == x ]; then
  todate=$(date '+%Y%m%d')
  eval "modseq=\$(echo '${allmodules}' | tr '\\t' ' ' | sed -r -e 's/^[0-9]{1,3}\\s+/ 999 /' -e's/\\s+[0-9]{1,3}\\s+/\\n/g' | cut -d' ' -f1 | grep 'fixse${todate}' | cut -c14-15 | sort -n | tail -1)"
  if [[ ${modseq} != '' && ${modseq} =~ ^[0-9]{2}$ ]]; then
    if [ ${modseq%[0-9]} -eq 0 ];then
      modseq="0$(( ${modseq#[0-9]} + 1 ))"
    else
      modseq=$(( ${modseq} + 1 ))
    fi
  else
    modseq=01
  fi
  modname="fixse${todate}${modseq}"
else
  eval "modseq=\$(echo '${allmodules}' | tr '\\t' ' ' | sed -r -e 's/^[0-9]{1,3}\\s+/ 999 /' -e's/\\s+[0-9]{1,3}\\s+/\\n/g' | cut -d' ' -f1 | grep '^${modname}$')"
  if [ "${modseq}x" != x ]; then
    echo "removing the same module first: semodule -r ${modname}"
    eval "semodule -r ${modname}"
  fi
fi
[ $? -eq 0 ] || exit $?

sedir="${sedir:-$defaultsedir}"
logdir="${sedir}/log"
tefile="${tedir:=${sedir}/te}/${modname}.te"
modfile="${moddir:=${sedir}/mod}/${modname}.mod"
ppfile="${ppdir:=${sedir}/pp}/${modname}.pp"

# prepare dir
eval "predir '$sedir'"
eval "predir '$logdir'"
eval "predir '$tedir'"
eval "predir '$moddir'"
eval "predir '$ppdir'"

if [ $create_default_flag_file -eq 1 ]; then
  touch $defaultsedir/.default_flag
fi

# prepare default log file
if [ "${logfile}x" == x ]; then
  defaultlog=1
  logfile="${logdir}/${modname}.log"
  echo "audit2why -alw > ${logfile}"
  eval "audit2why -alw > ${logfile}"
  [ $? -eq 0 ] || exit $?
  echo "audit2why -dw >> ${logfile}"
  eval "audit2why -dw >> ${logfile}"
  [ $? -eq 0 ] || exit $?
  eval "logline=\$(cat '${logfile}' | wc -l)"
  if [ $logline -eq 0 ]; then
    echo '[NOTICE] empty log, exit..'
    exit 1
  fi
fi

# create .te file
eval "overjudge '${tefile}'"
echo "audit2allow -i '${logfile}' -m '${modname}' > '${tefile}'"
eval "audit2allow -i '${logfile}' -m '${modname}' > '${tefile}'"
[ $? -eq 0 ] || exit $?
eval "teline=\$(cat '${tefile}' | sed -n '/^module/p' | wc -l)"
if [ $teline -ne 1 ]; then
  echo '[NOTICE] empty or invalid "te" file, exit..'
  exit 1
fi

# compile module
eval "overjudge '${modfile}'"
echo "checkmodule -M -m -o '${modfile}' '${tefile}'"
eval "checkmodule -M -m -o '${modfile}' '${tefile}'"
[ $? -eq 0 ] || exit $?

# package module
eval "overjudge '${ppfile}'"
echo "semodule_package -o '${ppfile}' -m '${modfile}'"
eval "semodule_package -o '${ppfile}' -m '${modfile}'"

errorcode=$?
if [ $errorcode -eq 0 ]; then
  echo ""
  echo ">>> SUCCESS, module [${modname}] generated."
  echo -e ">>> you can now   check the policy by run: \e[1;32mcat\e[0m \e[4;37m${tefile}\e[0m"
  [ $defaultlog -eq 0 ] || \
  echo -e ">>>            check the audit log by run: \e[1;32mcat\e[0m \e[4;37m${logfile}\e[0m"
  echo -e ">>>             import this module by run: \e[1;32msemodule\e[0m \e[1;37m-i\e[0m \e[4;37m${ppfile}\e[0m"
  echo ""
else
  echo "[ERROR]  something error."
  exit $errorcode
fi
