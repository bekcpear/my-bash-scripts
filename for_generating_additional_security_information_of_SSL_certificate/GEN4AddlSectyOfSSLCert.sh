#!/bin/bash
#
# Written by Bekcpear <i@ume.ink>
# under the GNU General Public License v2.0
# LICENSE: https://github.com/Bekcpear/my-bash-scripts/blob/master/LICENSE
# Project: https://github.com/Bekcpear/my-bash-scripts
#
# run `./GEN4AddlSectyOfSSLCert.sh help` to show help
#
# In addition to the basic GNU Core Utilities and BASH, but also need:
#   "openssl", "grep", "awk", "sed" to extra Base64-encoded SPKI fingerprint from a certificate
#   "go", "wget", "tar", "gzip", "awk", "sed" to get SCTs from log servers
#   "openssl", "grep", "awk", "sed" to generate DH parameters
# 

# path of the executable openssl binary
openSSL='/usr/bin/openssl'

# number of bits in to generate DH parameters
numbits=2048

# verbose mode
#   0 for only script error output
#   1 for script info/error output
#   2 for script info/error and command executed within this script error output
#   3 for all output
verbose=2

# overrided switch
#   1 means that do not show nofitication when file will be overrided
#   others are the opposite of 1
overrided=0

# parameters for installing ct-submit tool 
ctSubmitURL='https://github.com/grahamedgecombe/ct-submit/archive/v1.1.2.tar.gz'
ctSubmitDLPkg='./ct-submit-1.1.2.tar.gz'
ctSubmitVeriMethod='sha256sum'
ctSubmitVeriParam='f41702c86f4f1cb68274c0b3deed68016471dc443bd7f5665b5ae709e55d7af1'


#
##
### DO NOT MODIFY FOLLOWING VARIABLES
statCode=0
dlPkgPath=''
extPkgPath=''
# path of the output directory/file
#   For SCTs
#     directory path to store Signed Certificate Timestamps files
#   For DHParam
#     file path of the DHParam file that will be generated
opPath=''
# path array of input certificates
#   For SCTs
#     which used to get Signed Certificate Timestamps file from log servers
#     just use the 0 index of this array
#     the file should contain the server certificate and all intermediate certificates in order
#   For HPKP
#     which used to extra base64 encoded information
#     each file should be only one certificate content
declare -a certsPathArr

# standard out/err for generated informations from this script
gstdout='/dev/stdout'
gstderr='/dev/stderr'
# standard out/err for commands which executed within this script
cstdout='/dev/null'
cstderr='/dev/stderr'
tmpout=''
yn=''

# Log informations
# depend on [echo] [date] [pwd] [grep] [wc] [sed] [seq]
# Arguments:  $1 -> error 1, warn 2, exec 3, file 4, infoOut 5, necessary 6, normal 0
#             $2 -> msg
#             $3 -> flag, only used within this function
function log() {
  local info=$(date '+%H:%M:%S')' '$(pwd)']'
  local colorS='\e[0m'
  local color=''
  local colorE='\e[0m'
  local out=$gstdout
  local noti='info'
  local msg=$2
  local abort=0
  case $1 in
    1)
      colorS='\e[1;31m'
      out=$gstderr
      noti='err '
      ;;
    2)
      colorS='\e[1;33m'
      out=$gstderr
      noti='warn'
      ;;
    3)
      msg='  EXEC: '${msg}
      ;;
    4)
      if [ "$3"x == "sx" ]; then
        color='\e[1;32m'
        out=$gstderr
        msg='  FILE: '${msg}
      else
        if [ -f "$msg" ]; then
          eval "ex 'ls -l $msg' 2"
          eval "log 4 '$tmpout' s"
        elif [ -d "$msg" ]; then
          eval "ex 'ls -l \"$msg\" | grep -E \"^[-a-z]{10}\\\.?\\\s\" | wc -l' 2"
          local lines="$tmpout"
          [[ $lines =~ ^[0-9]+$ ]] || \
            eval "log -1 $LINENO"
          eval "log 4 'under directory ${msg}' s"
          for i in $(seq 1 $lines); do
            eval "ex 'ls -l \"$msg\" | grep -E \"^[-a-z]{10}\\\.?\\\s\" | sed -n ${i}p' 2"
            eval "log 4 '$tmpout' s"
            if [[ $i -eq 5 && $lines -gt 5 ]]; then
              eval "log 4 '...' s"
              break
            fi
          done
        fi
        return
      fi
      ;;
    5)
      color='\e[1;32m'
      out=$gstderr
      msg='  '${msg}
      ;;
    6)
      out=$gstderr
      ;;
    0)
      ;;
    *)
      color='\e[1;31m'
      out='/dev/stderr'
      noti='err '
      abort=1
      eval "msg='GEN4AddlSectyOfSSLCert script internal error at line $msg. Abort!'"
      ;;
  esac
  color=${color:-$colorS}
  eval "echo -e '  ${colorS}[${noti} ${info} ${color}${msg}${colorE}' > ${out}"
  if [ $abort == 1 ]; then
    exit 1
  fi
}

# Abort this script
# Argument:   $1 -> message
#             $2 -> 1 means should show help msg
function abort() {
  if [ "$2"x == "1x" ]; then
    eval "log 1 '$1'"
    showHelp
  else
    eval "log 1 '$1, abort!'"
  fi
  exit 1;
}

# Execute command (not functions)
# Arguments:  $1 -> whole command line string
#             $2 -> 1 means don't abort script whether status code is zero or not
#                   2 means redirect stdout to global variable, [tmpout]
#             $3 -> stdout for current command
#             $4 -> stderr for current command
# Global parameter: statCode, tmpout
function ex() {
  local ccstdout=${3:-$cstdout}
  local ccstderr=${4:-$cstderr}

  [ -f "$ccstdout" ] && eval "overrideNotif $ccstdout"
  [ -f "$ccstderr" ] && eval "overrideNotif $ccstderr"

  local cmdS=''
  if [ "$2"x == "2x" ]; then
    eval "cmdS=', tmpout=\$($1 > /dev/stdout 2> $ccstderr),'"
    eval "tmpout=\$($1 > /dev/stdout 2> $ccstderr)"
  else
    eval "log 3 '$1 > $ccstdout 2> $ccstderr'"
    eval "$1 > $ccstdout 2> $ccstderr"
  fi
  statCode=$?
  if [ "$2"x != "1x" -a $statCode != 0 ]; then
    eval "abort 'command${cmdS} executed error with status code: ${statCode}'"
  fi
}

# notify when file will be overrided
# depend on [read]
# Arguments:  $1 -> path
# Global parameter: overridedC
function overrideNotif() {
  [ -z "$1" ] && eval "log -1 $LINENO"
  if [ $overridedC -ne 1 ]; then
    eval "ex 'read -n 1 -rep \"override existing file ${1} [y/n]? \" yn' 0 '/dev/stdout' '/dev/stderr'"
    [ "$yn" != "y" ] && abort 'do not override file'
  fi
}

# Delete file or directory
# depend on [rm] [pwd]
# Arguments:  $1 -> path
#             $2 -> set to 1 for directory, empty or others for file
function del() {
  if [[ $1 =~ ^/[^/]*/?$ || ( $(pwd) == / && $1 =~ ^(\./)?[^/]*/?$ ) ]]; then
    eval "abort 'removing $1 is a dangerous action'"
  else
    [ "$2"x == "1x" ] && local opt='-rf' || local opt='-f'
    eval "ex 'rm $opt $1'"
  fi
}

# Prepare directory / check file existed or not
# depend on [mkdir] [sed]
# Argument:   $1 -> path
#             $2 -> 0 prepare dir for dir
#                   1 prepare dir for file
#                   2 check file
#             $3 -> for check file
#                    0/empty: abort if nonexistent/unreadable
#                    1: show notification due to be overrided
function prepPath(){
  local path="$1"
  [ -z "$path" ] && eval "log -1 $LINENO"
  case $2 in
    0);;
    1)
      eval "ex 'echo \"$path\" | sed \"s/\\\/[^/]*$//\"' 2"
      path="$tmpout"
      ;;
    2)
      if [ "$3"x == "x" -o "$3"x == "0x" ]; then
        [ -f "$path" ] || \
          eval "abort 'noexistent file $path, or its not a regular file'"
        [ -r "$path" ] || \
          eval "abort 'has no read permission to $path'"
      elif [ "$3"x == "1x" ]; then
        if [ -f "$path" ]; then
          eval "overrideNotif $path"
          [ -w "$path" ] || eval "abort 'has no write permission to $path'"
        fi
      fi
      return
      ;;
    *)
      eval "log -1 $LINENO"
      ;;
  esac
  if [ ! -e "$path" ]; then
    eval "ex 'mkdir -p \"$path\"'"
  elif [ ! -d "$path" ]; then
    eval "abort '$path exist but is not a directory'"
  elif [ ! -w "$path" ]; then
    eval "abort 'has no write permission under $path'"
  fi
}

# Download and Verify
# depend on [wget] [sha256sum] [date]
# Arguments:  $1 -> url
#             $2 -> local storage path, with filename
#             $3 -> verification method, sha256sum now
#                   (empty for no verify, 1 for force to download)
#             $4 -> verification parameter, sha256sum now
#             $5 -> 1 and up means force to download
# Global parameter: dlPkgPath
function dAndV() {
  dlPkgPath=$2
  eval "log 0 'Download $1 to $dlPkgPath'"
  if [[ ( -n $3 && $3 -eq 1 ) || ( -n "$5" && $5 -ge 1 ) ]]; then
    eval "del $dlPkgPath"
  fi
  if [ -f "$dlPkgPath" ]; then
    eval "log 0 '$dlPkgPath already exists'"
    if [ ! -r "$dlPkgPath" ]; then
      eval "log 2 '$dlPkgPath has no read permission'"
      dlPkgPath=${dlPkgPath}.$(date '+%H%M%S')
      eval "log 2 'download file to $dlPkgPath'"
    fi
  fi
  if [ ! -f "$dlPkgPath" ]; then
    eval "prepPath '$dlPkgPath' 1"
    eval "ex 'wget $1 -O $dlPkgPath'"
  fi

  if [ -n "$3" -a "$3" != "1" ]; then
    eval "log 0 'verify $dlPkgPath by $3 method'"
    local verified=0
    [ -z "$4" ] && abort 'verification parameter is empty'
    case $3 in
      sha256sum)
        eval "ex 'echo $4  $dlPkgPath | sha256sum -c --status' 1"
        if [ $statCode == 0 ]; then
          verified=1
        elif [[ -z $5 || $5 -eq 0 ]]; then
          verified=-1
        fi
        ;;
      *)
        eval "log -1 $LINENO"
        ;;
    esac
    if [ $verified -eq -1 ]; then
      log 2 'verification failed, try again..'
      eval "dAndV $1 $2 $3 $4 1"
    elif [ $verified -eq 0 ]; then
      eval "abort 'verification FAILED for downloaded package $dlPkgPath'"
    fi
  fi
}

# Extra package
# depend on [tar] [gzip] [head] [tail] [awk] [read]
# Argument:   $1 -> pkg path
# Global parameter: extPkgPath
function extra() {
  eval "prepPath '$1' 2"
  eval "ex 'tar -tf $1 | head -n 1 | awk -F \"/\" \"{printf \\\$1}\"' 2"
  eval "local d0=$tmpout"
  eval "ex 'tar -tf $1 | tail -n 1 | awk -F \"/\" \"{printf \\\$1}\"' 2"
  eval "local d1=$tmpout"
  if [ "$d0"x == "$d1"x ]; then
    eval "ex 'tar -xf $1'"
    extPkgPath=$d0
  else
    local array=''
    eval "ex 'IFS=/ read -r -a array <<< \"$1\"'"
    extPkgPath=${array[$((${#array[@]} - 1))]}
    eval "extPkgPath=\$(echo $extPkgPath | sed 's/.tar\(.[a-z]\+\)\?$//i')"
    eval "prepPath '$extPkgPath' 0"
    eval "ex 'tar -C $extPkgPath -xf $1'"
  fi
}

# Generate DH parameters
# depend on [openssl]
# Global parameter: opPath, numbitsC
function genDHParam() {
  log 0 'Generating DHParam...'
  eval "prepPath '$opPath' 2 1"
  eval "prepPath '$opPath' 1"
  eval "ex '$openSSL dhparam -outform PEM -out $opPath $numbitsC'"
  eval "log 4 '$opPath'"
  log 0 'DHParam generated.'
}

# Get Signed Certificate Timestamps
# depend on [ct-submit] [golang]
# Global parameter: certsPathArr, opPath, dlPkgPath, extPkgPath
function genSCTs() {
  log 0 'Get SCTs...'

  ex 'cd /tmp'
  eval "dAndV '$ctSubmitURL' '$ctSubmitDLPkg' '$ctSubmitVeriMethod' '$ctSubmitVeriParam'"
  extra $dlPkgPath
  eval "ex 'cd $extPkgPath'"

  ex 'go build .'
  eval "ex 'chmod +x ./$extPkgPath'"

  eval "prepPath '$opPath' 0"
  eval "ex './$extPkgPath ct.googleapis.com/icarus <${certsPathArr[0]}' 0 '${opPath}/icarus.sct'"
  eval "log 4 '${opPath}/icarus.sct'"
  eval "ex './$extPkgPath ct.googleapis.com/rocketeer <${certsPathArr[0]}' 0 '${opPath}/rocketeer.sct'"
  eval "log 4 '${opPath}/rocketeer.sct'"
  log 0 'SCTs got.'

  ex 'cd /tmp'
  eval "del '$dlPkgPath'"
  eval "del './$extPkgPath' 1"
}

# Get the pin-sha256 of certificates which used to enable HTTP Public Key Pinning (HPKP)
# depend on [openssl] [grep] [awk]
# Global parameter: certsPathArr, openSSL
function genFP4Cert() {
  log 0 'Extracting the base64 encoded information from the certificate...'
  local doing=1
  for cert in ${certsPathArr[@]};
  do
    eval "ex '$openSSL x509 -in $cert -pubkey -noout -text | grep \"Public Key Algorithm\" | awk -F \": \" \"{printf \\\$2}\"' 2"
    eval "local algorithm=$tmpout"
    case $algorithm in
      rsaEncryption)
        local cmd='rsa'
        ;;
      id-ecPublicKey)
        local cmd='ec'
        ;;
      *)
        eval "abort 'Public Key Algorithm exception (has algorithm $algorithm)'"
        ;;
    esac
    eval "ex '$openSSL x509 -in $cert -pubkey -noout | $openSSL $cmd -pubin -outform der 2> $cstderr | $openSSL dgst -sha256 -binary | $openSSL enc -base64' 2"
    eval "log 6 'PIN-SHA256 of $cert is:'"
    eval "log 5 '$tmpout'"
    doing=0
  done
  [ $doing -eq 0 ] && \
    log 0 'Base64 encoded information of the certificate has been extracted.' || \
    log 2 'No valid certificate path.'
}

# Show help information
# depend on [echo]
function showHelp() {
  echo
  eval "echo '  Usage: $0 COMMAND OPTION(S)'"
  echo
  echo '  COMMAND'
  echo '    dhparam      generate a file of DH parameters'
  echo '    sct          get Signed Certificate Timestamps'
  echo '    hpkp         extra the Base64 encoded SPKI fingerprint'
  echo
  echo '    help(-h)     show this help'
  echo
  echo '  OPTIONS (for all)'
  [ $overrided -ne 1 ] && \
    echo '    -f               force to override file when the file already exists'
  eval "echo '    -v <num>         verbose mode (default $verbose)'"
  echo '                       0: only script error'
  echo '                       1: script info/error'
  echo "                       2: 1's & command error"
  echo '                       3: all'
  echo '  OPTIONS (for dhparam)'
  echo '    -o <path>        path of the generated file'
  eval "echo '    -b <num>         number of bits in to generate (default $numbits)'"
  echo '  OPTIONS (for sct)'
  echo '    -i <path>        path of the certificate chain file'
  echo '    -o <path>        path of directory which store the SCTs files'
  echo '  OPTION  (for hpkp)'
  echo '    -i <path>        path of the certificate, can be used multiple times'
  echo
}

# Handle script options
# depend on [getopts] [shift]
# Global parameters:
#           docmd -> choose which file/info should be generated
#                      dhparam : generate the DH parameters file
#                      sct     : get the SCTs from log servers
#                      hpkp    : extra base64-encoded SPKI fingerprint from a cert
#           doopt -> options
#                    the meaning of its value is according to the above docmd-value
certsNum=0
docmd="$1"
if [[ ! $docmd =~ ^dhparam|sct|hpkp$ ]];then
  if [ "$docmd"x == "helpx" -o "$docmd"x == "-hx" ]; then
    showHelp
    exit 0
  fi
  eval "abort 'invalid command: $docmd' 1"
fi
shift
while getopts ":v:i:b:o:f" doopt;
do
  case $doopt in
    v)
      [[ $OPTARG =~ ^0|1|2|3$ ]] && \
        verboseC=$OPTARG || \
        eval "abort 'invalid argument: -${doopt} ${OPTARG}' 1"
      ;;
    i)
      [ -z "$OPTARG" ] && \
        eval "abort 'invalid argument: -${doopt} ${OPTARG}' 1"
      eval "certsPathArr[${certsNum}]='${OPTARG}'"
      eval "certsNum=\$(( ${certsNum} + 1 ))"
      ;;
    b)
      [[ $OPTARG =~ ^[0-9]+$ ]] && \
        numbitsC=$OPTARG || \
        eval "abort 'invalid argument: -${doopt} ${OPTARG}' 1"
      ;;
    o)
      [ -z "$OPTARG" ] && \
        eval "abort 'invalid argument: -${doopt} ${OPTARG}' 1"
      opPath=$OPTARG
      ;;
    f)
      overridedC=1
      ;;
    ?)
      eval "abort 'invalid argument: -${OPTARG}' 1"
      ;;
  esac
done
verboseC=${verboseC:-$verbose}
numbitsC=${numbitsC:-$numbits}
overridedC=${overridedC:-$overrided}
case $verboseC in
  0)
    gstdout='/dev/null'
    cstderr='/dev/null'
    ;;
  1)
    cstderr='/dev/null'
    ;;
  2)
    ;;
  3)
    cstdout='/dev/stdout'
    ;;
esac

# Execute main function
case $docmd in
  dhparam)
    [[ ( ! $numbitsC =~ ^[0-9]+$ ) || $numbitsC < 1024 ]] && numbitsC=$numbits
    [ -z "$opPath" ] && \
      abort 'no output DHParam file path specified' || \
      genDHParam
    ;;
  sct)
    [ -z "${certsPathArr[0]}" ] && \
      abort 'no certificate file specified'
    [ -z "$opPath" ] && \
      abort 'no output directory specified for storing SCTs'
    genSCTs
    ;;
  hpkp)
    [ ${#certsPathArr[@]} -lt 1 ] && \
      abort 'no certificate file(s) specified'
    genFP4Cert
    ;;
esac
