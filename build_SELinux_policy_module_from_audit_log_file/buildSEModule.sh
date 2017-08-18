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

action=0
defaultsedir=$HOME'/.selinux_module_gen_dir'
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
      echo -e "\e[1;31m[ERROR]  $1 existed and is not a regular file.\e[0m" > /dev/stderr
      exit 1
    fi
  fi
}

function predir(){
  if [ ! -e "$1" ]; then
    eval "mkdir -p '$1'"
    echo "[NOTICE] created directory $1"
  elif [ ! -d "$1" ]; then
    echo -e "\e[1;31m[ERROR]  $1 existed but is not a directory.\e[0m" > /dev/stderr
    exit 1
  elif [ ! -w "$1" ]; then
    echo -e "\e[1;31m[ERROR]  no write permission under $1\e[0m" > /dev/stderr
    exit 1
  fi
}

function showhelp() {
cat <<EOT

  !!IMPORTANT!! this script use default priority now

  Usage 0: $0 [OPTIONS] [MODULENAME]

    The default module name is "fixse<date><sequence>", e.g.: fixse2017081501

    -i <file>        audit log file
                     (default read all from audit, message and dmesg logs since last policy reload)
    -t <dir>         .te file directory (default [dir]/te)
    -m <dir>         .mod file directory (default [dir]/mod)
    -o <dir>         the generated .pp file directory (default [dir]/pp)

  Usage 1: $0 revoke [OPTIONS] [MODULENAME]

    Remove the specified module, and remove the all corrensponding files (except log).
    The default module name is the last generated module.

  Global options:
    -d <dir>         main directory of this script [dir] (default $defaultsedir)
    -f               force to override existed files / remove corrensponding files
    -h               print this help

EOT
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
      echo -n 'continue to generate module with default settings[c]  help[h]  exit[q]: '
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
        *)
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

fistactsetted=0
while [[ ! ${1} =~ ^- && ${1} != '' && ( ${fistactsetted} == 0 || ${modname_setted} == 0) ]]; do
  if [ "${1}x" == "revokex" ]; then
    action=1
    fistactsetted=1
    shift
  elif [ ${modname_setted} -eq 0 ];then
    setmodname "${1}"
    shift
  fi
done

if [ ${action} -eq 0 ]; then
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
        optindd=$(($OPTIND - 1))
        eval "echo \"[NOTICE] ignore argument \$${optindd}\""
        ;;
    esac
  done
else
  while getopts ":d:fh" doopt;
  do
    case ${doopt} in
      d)
        sedir="${OPTARG%%/}"
        ;;
      f)
        overridedF=1
        ;;
      h)
        showhelp
        exit 0
        ;;
      ?)
        optindd=$(($OPTIND - 1))
        eval "echo \"[NOTICE] ignore argument \$${optindd}\""
        ;;
    esac
  done
fi

shift $((${OPTIND} - 1))
if [ "${1}x" != x ]; then
  if [ ${modname_setted} -eq 0 ];then
    setmodname "${1}"
  else
    echo -e "\e[1;31m[ERROR]  redundant module settings\e[0m" > /dev/stderr
    showhelp
    exit 1
  fi
  shift
  echo "[NOTICE] ignore argument(s) $@"
fi

allmodules=$(semodule -lfull)
[ $? -eq 0 ] || exit $?

todate=$(date '+%Y%m%d')
sedir="${sedir:-$defaultsedir}"

if [ ${action} -eq 0 ]; then
  modnamechecked=0
  if [ "${modname}"x == x ]; then
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
    modnamechecked=1
  fi

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
    eval "overjudge '${logfile}'"
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

  if [ ${modnamechecked} -eq 0 ]; then
    eval "modseq=\$(echo '${allmodules}' | tr '\\t' ' ' | sed -r -e 's/^[0-9]{1,3}\\s+/ 999 /' -e's/\\s+[0-9]{1,3}\\s+/\\n/g' | cut -d' ' -f1 | grep '^${modname}$')"
    if [ "${modseq}x" != x ]; then
      echo "removing the same module first: semodule -r ${modname}"
      eval "semodule -r ${modname}"
      [ $? -eq 0 ] || exit $?
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
    echo -e "\e[1;31m[ERROR]  something error.\e[0m" > /dev/stderr
    exit $errorcode
  fi
else
  modloaded=0
  addopt=''
  modseq=0
  modseqgen=0
  modloopcount=10
  modselected=0
  moddate=${todate}

  if [ "${modname}"x == x ]; then
    addopt=''
    while [ ${modselected} -eq 0 -a ${modloopcount} -gt 0 ]; do
      eval "modseqgen=\$(find ${sedir} -name '*${moddate}*.pp'| awk -F'/' '{printf \$NF\"\\n\"}'${addopt} | cut -c6-15 | sort -n | tail -1)"
      if [[ ${modseqgen} != '' && ${modseqgen} =~ ^[0-9]{10}$ ]]; then
        modselected=1
      fi
      modloopcount=$((${modloopcount} - 1))
      eval "moddate_sec=\$(date -d $moddate +%s)"
      moddate_sec=$(($moddate_sec - 86400))
      eval "moddate=\$(date -d @$moddate_sec +%Y%m%d)"
    done

    if [ ${modselected} -eq 0 -a ${modseqgen}x == x ]; then
      echo '[NOTICE] No module generated in the past 10 days. exit..'
      exit 1
    fi
  else
    addopt=" | grep ${modname}"
    eval "modseqgen=\$(find ${sedir} -name '${modname}.*')"
    if [[ ${modseqgen} == '' ]]; then
      echo "[NOTICE] No generated module [${modname}] in the directory ${sedir}"
      echo -e "         Try run this cmd manually to remove it: \e[1;32msemodule\e[0m \e[1;37m-r\e[0m \e[1;33m${modname}\e[0m"
      exit 1
    fi
  fi

  eval "modseq=\$(echo '${allmodules}' | tr '\\t' ' ' | sed -r -e 's/^[0-9]{1,3}\\s+/ 999 /' -e's/\\s+[0-9]{1,3}\\s+/\\n/g' | cut -d' ' -f1 | grep 'fixse'${addopt} | cut -c6-15 | sort -n | tail -1)"
  if [ ${modname}x == x ]; then
    if [[ ${modseq} != '' && ${modseq} =~ ^[0-9]+$ ]]; then
      if [[ ${modseq} == ${modseqgen} ]]; then
        modname="fixse${modseq}"
        modloaded=1
        echo -n "[NOTICE] found module [${modname}], remove it? [y/N]: "
        read -n 1 -er ask
        if [ "${ask}x" != yx ]; then
          echo "not removed. exit.."
          exit 1
        fi
      else
        modname0="fixse${modseq}"
        modname1="fixse${modseqgen}"
        echo -n "[NOTICE] the latest loaded fixse-module [${modname0}] (a) does not match with the latest module [${modname1}] (b) in the directory ${sedir}, choose one of them or neither [a/b/N]: "
        read -n 1 -er ask
        case ${ask} in
          a)
            modname=${modname0}
            modloaded=1
            ;;
          b)
            modname=${modname1}
            ;;
          *)
            echo 'exit..'
            exit 1
            ;;
        esac
      fi
    else
      modname="fixse${modseqgen}"
    fi
  elif [[ ${modseq} != '' ]]; then
    modloaded=1
  fi

  if [ ${modloaded} -eq 0 ]; then
    echo "[NOTICE] The module [${modname}] was not loaded."
  else
    echo "semodule -r ${modname}"
    eval "semodule -r ${modname}"
    [ $? -eq 0 ] || exit $?
  fi
  if [ ${overridedF} -ne 1 ]; then
    echo -n "[NOTICE] Continue to remove all its files (except log) ? [y/N]: "
    read -n 1 -er ask
    if [ "${ask}x" != yx ]; then
      echo "not removed. exit.."
      exit 1
    fi
  fi
  eval "find '${sedir}' ! \\( -iname *.log \\) -name '${modname}*' -exec echo 'rm -f {}' \;"
  eval "find '${sedir}' ! \\( -iname *.log \\) -name '${modname}*' -exec rm -f '{}' \;"
  [ $? -eq 0 ] || exit $?
fi
