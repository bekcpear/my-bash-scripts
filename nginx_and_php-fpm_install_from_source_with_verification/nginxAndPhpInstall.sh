#!/usr/bin/bash
#
# Written by Bekcpear on Dec 23, 2016
#
# Description:
#   Environment is CentOS 7
#   Database(mariadb-server) is installed default by yum from base-repository
#   Nginx is compilied from source file.
#     - openssl and ctnginx(nginx-ct) is compiled to nginx bins, not compiled to system
#   PHP is compilied from source file.

#Four software name prefix
# nginx
# php
# ctnginx
# openssl

#Suffix definition
# _source                     a url is the software download from
# _source_asc                 a url is the corresponding pgp ASCII Armored file download from
# _source_asc_public_key      a url is the corresponding pgp public key download from
# _source_asc_public_key_id   a string what is the id of the corresponding pgp public key
# _source_asc_publuc_key_uid  a string what is the user id of the corresponding pgp public key
#                             (The full name and email address what can be used to reveive key online from pgp.mit.edu)
# _source_tar                 downloaded source tarball name (not path)
# _source_dir                 unpacked source file directory name (not path)
# _install_dir                which directory the software installed
# _conf_dir                   which directory the software's configuratin files stored
# run_dir                     only one directory for all softwares, store all pid files

## =================================================
## The variables you can set ==START==
## ** ALL THESE VARIABLES CAN BE SET EMPTY **
## ** AND THE SCRIPT WILL USE DEFAULT VALYE**
## =================================================
c_j='' # how many parallel jobs when makeing
c_debug='' # set 0:no original command output; 1:no stdout from original command; 2:show all output
c_soft_prefix_list='' # a array which store the necessory software prefix (e.g.: 'Four software name prefix' described above)
c_http_proxy='' #default is none
c_nginx_user=''
c_nginx_group=''
c_php_user=''
c_php_group=''
#some directory (use absolute path better)
c_src_dir='' #default is /opt/src
c_install_dir='' #default is /opt/local
c_nginx_install_dir='' #default is $c_install_dir/nginx
c_php_install_dir='' #default is $c_install_dir/php
c_conf_dir='' #default is /opt/conf
c_nginx_conf_dir='' #default is $c_conf_dir/php
c_php_conf_dir='' #default is $c_conf_dir/php
c_run_dir='' #default is /opt/run
#Url settings
# variable meanings can look up the 'Suffix definition' above
# Description:
# The variable comment at 'necessory or default' means you can at least set them to replace whole default settings (without verification)
# Example:
# c_nginx_source='http://nginx.org/download/nginx-1.11.7.tar.gz' #Mainline version
# c_nginx_source_asc='http://nginx.org/download/nginx-1.11.7.tar.gz.asc'
# c_nginx_source_asc_public_key='http://nginx.org/keys/mdounin.key'
# c_nginx_source_asc_public_key_id='B0F4253373F8F6F510D42178520A9993A1C052F8'
# c_nginx_source_asc_public_key_uid='Maxim Dounin <mdounin@mdounin.ru>'
c_nginx_source='' #necessory or default [url]
c_nginx_source_asc='' # [url]
c_nginx_source_asc_public_key='' # [url]
c_nginx_source_asc_public_key_fpr='' # [string]
c_nginx_source_asc_public_key_uid='' # [string]
#all default valus below is the latest stable relase on 23 Dec,2016
c_php_source='' #necessory or default
c_php_source_asc=''
c_php_source_asc_public_key=''
c_php_source_asc_public_key_fpr=''
c_php_source_asc_public_key_uid=''
c_openssl_source='https://www.openssl.org/source/openssl-1.1.0c.tar.gz' #necessory or default
c_openssl_source_asc='https://www.openssl.org/source/openssl-1.1.0c.tar.gz.asc'
c_openssl_source_asc_public_key=''
c_openssl_source_asc_public_key_id=''
c_openssl_source_asc_public_key_uid=''
c_ctnginx_source='' #necessory of default
c_ctnginx_source_asc=''
c_ctnginx_source_asc_public_key=''
c_ctnginx_source_asc_public_key_id=''
c_ctnginx_source_asc_public_key_uid=''

# Every configuration parameter in the below two variables will override the default configuration parameter separately.
# This means you can set a different parameter here and also use the default parameters without additional configuration.
# If the parameter's key is the same but has different value, value set here will override the default.
# If you want to unset a patameter, you can set in here like this: --with-debug=!
c_nginx_compile_conf="" #default parameters in line 135
c_php_compile_conf="" #default parameters in line 153
## =================================================
## The variables you can set ==E N D==
## =================================================
##

## =====================================================
## =====================================================
## =====================================================
## The default variables, do not modifiy them. ==START==
## =====================================================
## there is a useful variable which format like:
##    <software_name_prefix>_source_dir
##    (these global variables are defined in the process code)
#
http_proxy=${c_http_proxy:-''}
nginx_user=${c_nginx_user:-'nginx'}
nginx_group=${c_nginx_group:-'webService'}
php_user=${c_php_user:-'php-fpm'}
php_group=${c_php_group:-'webService'}
#Default location settings
src_dir=${c_src_dir:-'/opt/src'}
install_dir=${c_install_dir:-'/opt/local'}
nginx_install_dir=${c_nginx_install_dir:-''}
php_install_dir=${c_php_install_dir:-''}
conf_dir=${c_conf_dir:-'/opt/conf'}
nginx_conf_dir=${c_nginx_conf_dir:-''}
php_conf_dir=${c_php_conf_dir:-''}
run_dir=${c_run_dir:-'/opt/run'}

#Default url settings
nginx_source=${c_nginx_source:-'http://nginx.org/download/nginx-1.11.7.tar.gz'} # Mainline version
nginx_source_asc=${c_nginx_source_asc:-'http://nginx.org/download/nginx-1.11.7.tar.gz.asc'}
nginx_source_asc_public_key=${c_nginx_source_asc_public_key:-'http://nginx.org/keys/mdounin.key'}
nginx_source_asc_public_key_id=${c_nginx_source_asc_public_key_fpr:-'B0F4253373F8F6F510D42178520A9993A1C052F8'}
nginx_source_asc_public_key_uid=${c_nginx_source_asc_public_key_uid:-'Maxim Dounin <mdounin@mdounin.ru>'}
php_source=${c_php_source:-'http://jp2.php.net/get/php-7.1.0.tar.bz2/from/this/mirror'}
php_source_asc=${c_php_source_asc:-'http://jp2.php.net/get/php-7.1.0.tar.bz2.asc/from/this/mirror'}
php_source_asc_public_key=${c_php_source_asc_public_key:-''}
php_source_asc_public_key_id=${c_php_source_asc_public_key_fpr:-'A917B1ECDA84AEC2B568FED6F50ABC807BD5DCD0'} # Different version may has a different public key.
php_source_asc_public_key_uid=${c_php_source_asc_public_key_uid:-'Davey Shafik <davey@php.net>'}
openssl_source=${c_openssl_source:-'https://www.openssl.org/source/openssl-1.0.2j.tar.gz'}
openssl_source_asc=${c_openssl_source_asc:-'https://www.openssl.org/source/openssl-1.0.2j.tar.gz.asc'}
openssl_source_asc_public_key=${c_openssl_source_asc_public_key:-''}
openssl_source_asc_public_key_id=${c_openssl_source_asc_public_key_id:-'8657ABB260F056B1E5190839D9C4D26D0E604491'}
openssl_source_asc_public_key_uid=${c_openssl_source_asc_public_key_uid:-'Matt Caswell <matt@openssl.org>'}
ctnginx_source=${c_ctnginx_source:-'https://github.com/grahamedgecombe/nginx-ct/archive/v1.3.2.tar.gz'}
ctnginx_source_asc=${c_ctnginx_source_asc:-'https://github.com/grahamedgecombe/nginx-ct/releases/download/v1.3.2/v1.3.2.tar.gz.asc'}
ctnginx_source_asc_public_key=${c_ctnginx_source_asc_public_key:-'https://www.grahamedgecombe.com/gpe.asc'}
ctnginx_source_asc_public_key_id=${c_ctnginx_source_asc_public_key_id:-'D2B498F5C23753201BC7A020808A6AE4B9B44894'}
ctnginx_source_asc_public_key_uid=''

#Default compilation configurations (need to be quoted in a function)
function nginxConfFunc(){
eval "nginx_compile_conf='\
  --prefix=$nginx_install_dir \
  --conf-path=$nginx_conf_dir'/nginx.conf' \
  --user=$nginx_user \
  --group=$nginx_group \
  --with-http_realip_module \
  --with-http_sub_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-openssl=$openssl_source_dir \
  --with-http_ssl_module \
  --with-http_v2_module \
  --add-module=$ctnginx_source_dir \
  --with-debug \
  --with-pcre'"
}

function phpConfFunc(){
eval "php_compile_conf='\
  --prefix=$php_install_dir \
  --sysconfdir=$php_conf_dir \
  --enable-fpm \
  --with-fpm-user=$php_user \
  --with-fpm-group=$php_group \
  --with-mysqli \
  --with-libxml-dir \
  --with-gd \
  --with-jpeg-dir \
  --with-png-dir \
  --with-freetype-dir \
  --with-iconv-dir \
  --with-zlib-dir \
  --with-mcrypt \
  --with-curl \
  --with-pear \
  --with-gettext \
  --enable-bcmath \
  --enable-sockets \
  --enable-soap \
  --enable-gd-native-ttf \
  --enable-ftp \
  --enable-exif \
  --enable-tokenizer \
  --with-pdo-mysql \
  --enable-mbstring \
  --with-openssl'"
}
## Attention: need to set the '--with-pdo-mysql' to the right path when you use a custom mysql home directory
necessoryPackages="\
  bzip2 \
  gzip \
  xz \
  wget \
  gcc \
  make \
  re2c \
  autoconf \
  pcre-devel \
  zlib-devel \
  libxml2-devel \
  openssl-devel \
  bzip2-devel \
  libjpeg-devel \
  libpng-devel \
  gettext-devel \
  freetype-devel \
  libmcrypt-devel \
  libcurl-devel \
  bison-devel \
  bison \
  mariadb \
  mariadb-server"

#Default systemd service file content
function generateNginxSystemdServiceFile(){
  eval "echo '
[Unit]                                                                                                                                                     
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=$run_dir/nginx.pid
ExecStartPre=$nginx_install_dir/sbin/nginx -t -p $nginx_install_dir -c $nginx_conf_dir/nginx.conf
ExecStart=$nginx_install_dir/sbin/nginx -p $nginx_install_dir -c $nginx_conf_dir/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
' > /lib/systemd/system/nginx.service"
}

function generatePhpFpmSystemdServiceFile(){
  eval "echo '
[Unit]                                                                                                                                                     
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=simple
PIDFile=$run_dir/php-fpm.pid
ExecStart=$php_install_dir/sbin/php-fpm --nodaemonize --fpm-config $php_conf_dir/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
' > /lib/systemd/system/php-fpm.service"
}

## =====================================================
## The default variables, do not modifiy them. ==E N D==
## =====================================================

###########################################################################
###########################################################################
###########################################################################
###########  #####  ##########  ##########    #######  #######  ###########
###########   ###   #########    ##########  ########   ######  ###########
###########  #   #  ########  ##  #########  ########    #####  ###########
###########  ## ##  #######  ####  ########  ########  ##  ###  ###########
###########  #####  #######  ####  ########  ########  ###  ##  ###########
###########  #####  #######        ########  ########  ####  #  ###########
###########  #####  #######  ####  ########  ########  #####    ###########
###########  #####  #######  ####  ########  ########  ######   ###########
###########  #####  #######  ####  #######    #######  #######  ###########
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################

#Info echo function
# three parameters: $1:<info|warn|err>, $2:<msgstr> and $3:<show_time_no_not,default_is_show>
function infoe(){
  if [ "$2"x != ""x ];then
    local d=$(date '+%Y-%m-%d %H:%M:%S')
    d=$d" <$(pwd)> "
    [ "$3"x == "1"x ] && d=''
    case "$1" in
      info)
        echo "  ${d}$2"
        ;;
      warn)
        echo -e "  \e[1;33m${d}[Warning] $2""\e[0m"
        ;;
      err)
        echo -e "\e[1;31m${d}[Error] $2""\e[0m" > /dev/stderr
        ;;
    esac
  fi
}

#Dangerous action delay function
# two parameters: $1:<promptString> and $2:<countDownSeconds>
function countDown(){
  local d=$(date '+%Y-%m-%d %H:%M:%S')
  d=$d' '
  eval "echo -en '  $d$1 \e[1;33m$2'"
  sleep 1
  for i in $(seq 2 $2);do
    echo -n " $(($2-$i+1))"
    sleep 1
  done
  echo -e " 0\e[0m"
  echo
}

#Parse download package name function, need [tr]
# one parameter: <urlstr>
function parseUrlPkg(){
  local a=($(echo -n "$1" | tr '/' ' ' ))
  local pkg=""
  for name in ${a[*]};do
    [[ "$name" =~ ^[a-zA-Z]+-[0-9]+[.0-9a-z]+\.tar[.a-zA-Z]+[^(asc)]$ ]] && pkg="$name"
  done
  echo -n $pkg
}

#Current work directory check function
# one parameter: <which_dir>
function pwdCheck(){
  eval "local dir=\$$1"
  if [ "$(pwd)" != "$dir" ];then
    eval "mkdir -p '$dir'"
    eval "cd $dir"
  fi
}

#Download function, need [wget]
# two parameters: $1:<urlstr> and $2:<package_name>
function dl(){
  local verbose='-nv'
  [ "$main_out_put"x == "/dev/stdout"x ] && verbose="-v"
  pwdCheck 'src_dir'
  if [ -f "$2" ];then
    eval "infoe 'info' 'File $2 exist, skiping download'"
  else
    eval "infoe 'info' '-Downloading $2 to $(pwd) ...'"
    eval "https_proxy='$http_proxy' http_proxy='$http_proxy' wget '$1' -O '$2' $verbose > $main_out_put 2> $err_out_put"
    [ $? -ne 0 ] && { eval "infoe 'err' 'Download $1 Error'"; [[ "$2" =~ (.asc)|(.key)$ ]] && eval "infoe 'err' 'If you really cannot get the correct pgp verification file url, you can add parameter '-n' to this script. BUT it is not recommended.'"; exit 1; }
    eval "infoe 'info' '$2 downloaded'"
  fi
}

#Interact choice function
# three parameter: $1:<prompt>, $2:<confirmPromptInfoType> and $3:<confirmPrompt>
function choiceyn(){
  if [ $confirmstep -eq 0 ];then
    eval "infoe '$2' '$3'"
  else
    while read -n 1 -rep "  $1 " read_para;do
      case $read_para in
        y)
          eval "infoe '$2' '$3'"
          break
          ;;
        n)
          eval "infoe 'info' 'ok, bye~' 1"
          exit
          ;;
        *)
          continue
      esac
    done
  fi
}

#Gpg checking function, need [gpg], [sed], [awk], [cut]
# two parameters: $1:<software_name_prefix> and $2:<package_name>
function gpgCheck(){
  eval "infoe 'info' 'Verifying file $2 ...'"
  local asc_url_pname=$1'_source_asc'
  local key_url_pname=$1'_source_asc_public_key'
  eval "local asc_url=\$$asc_url_pname"
  local asc_file=$2'.asc'
  pwdCheck 'src_dir'
  eval "dl $asc_url $asc_file"
  if [ -f "$2" ];then
    local gpg_out=$(eval "gpg --verify '$asc_file' '$2' 2> /dev/stdout"; echo "#verify#$?#verify#") # verify file 1st place
    local gpg_tmp_status=$(echo $gpg_out | awk -F '#verify#' '{printf $2}')
    [ $debug -eq 1 ] && printf "$gpg_out \n" | sed 's/#verify#[0-9]#verify#//'
    [ $gpg_tmp_status -eq 1 ] && eval "infoe 'err' 'File $2 is verified failed, please check the download link or file.'" && exit 1
  else
    eval "infoe 'err' 'File $2 not exist.'"
    exit 1
  fi
  if [ $gpg_tmp_status -ne 0 ];then # gpg error code 2 this means no corresponding public key while 1 is verify failed
    eval "local key_url=\$$key_url_pname"
    local key_file=$2'.key'
    local id_pname=$1'_source_asc_public_key_id'
    local uid_pname=$1'_source_asc_public_key_uid'
    eval "local id=\$$id_pname"
    eval "local uid=\$$uid_pname"
    if [ "$key_url"x == ""x ];then
      local method='receive'
      if [ "$id"x == ""x ];then
        local method='search'
        if [ "$uid"x == ""x ];then
          eval "infoe 'err' 'No public key provided.Abort.'"
          exit 1
        fi
      fi
    else
      local method='download'
    fi
    while [ $? -eq 0 ];do
      case "$method" in
        download)
          eval "infoe 'info' '-Downloading public key from $key_url ...'"
          eval "dl $key_url $key_file"
          eval "gpg --import '$key_file' > $main_out_put 2>$err_out_put" && eval "infoe 'info' '$key_file imported'" && break
          if [ $? -ne 0 ];then
            eval "infoe 'err' 'import from downloaded file $key_file err.'"
            if [ "$id"x != ""x ];then
              method='receive'
              eval "infoe 'info' 'Try import key by id $id from default server...'"
            elif [ "$uid"x != ""x ];then
              method='search'
              eval "infoe 'info' 'Try search key by user id $uid from default server...'"
            else
              eval "infoe 'err' 'import public key err. Abort.'"
              exit 1
            fi
            continue
          fi
          ;;
        receive)
          eval "infoe 'info' '-Receiving public key $id from default server...'"
          eval "https_proxy='$http_proxy' http_proxy='$http_proxy' gpg --recv-keys $id > $main_out_put 2>$err_out_put" && eval "infoe 'info' '$id imported'" && break
          if [ $? -ne 0 ];then
            eval "infoe 'err' 'import key $id error.'"
            if [ "$uid"x != ""x ];then
              method='search'
              eval "infoe 'info' 'Try search key by user id $uid from default server...'"
            else
              eval "infoe 'err' 'import public key err. Abort.'"
              exit 1
            fi
            continue
          fi
          ;;
        search)
          eval "infoe 'info' '-Searching public key by user name $uid from default server...'"
          eval "https_proxy='$http_proxy' http_proxy='$http_proxy' gpg --search-keys '$uid'" && eval "infoe 'info' '$uid imported'" && break
          if [ $? -ne 0 ];then
            eval "infoe 'err' 'import public key error.Abort.'"
            exit 1
          fi
          ;;
      esac
    done
    local gpg_out=$(eval "gpg --verify '$asc_file' '$2' 2> /dev/stdout"; echo "#verify#$?#verify#")
    local gpg_tmp_status=$(echo $gpg_out | awk -F '#verify#' '{printf $2}')
    [ $debug -eq 1 ] && printf "$gpg_out \n" | sed 's/#verify#[0-9]#verify#//'
    [ $gpg_tmp_status -eq 1 ] && eval "infoe 'err' 'File $2 is verified failed, please check the download link or file.'" && exit 1; # verify file 2nd place
  fi
  local fpr_pname=$1'_source_asc_public_key_id'
  eval "local fpr=\$$fpr_pname"
  if [ "$fpr"x == ""x ];then
    eval "infoe 'warn' 'no fingerprint provided, cannot verify the public is trusted or not.'"
    choiceyn 'continue?[y/n]' 'warn' 'not full verified, but you choice continue.'
  else
    gpg_out=$(echo $gpg_out | sed 's/#verify#[0-9]#verify#//')
    local fpr_now=$(echo $gpg_out | grep 'fingerprint' | awk -F 'Primary key fingerprint:' '{printf $2}' | cut -c -50 - | sed 's/\s//g')
    [ $debug -eq 1 ] && eval "infoe 'info' 'The fingerprint is $fpr_now'"
    if [ "$fpr"x == "$fpr_now"x ];then
      eval "infoe 'info' 'File $2 is verified success.'"
    else
      eval "infoe 'err' 'File $2 is verified failed, fingerprint is not matched.Abort.'"
      exit 1
    fi
  fi
}

#Compilation's configurations prepare function, need [sed],[awk]
# two parameters: $1:<default_config_parameters_name> and $2:<custom_config_parameters_name>
function confCompare(){
  eval "local cd=\$(echo \$$1 | sed 's/\s/<space>/g')"
  eval "local cc=\$(echo \$$2 | sed 's/\s/<space>/g')"
  if [[ "$cc" =~ ^\s*$ ]];then
    eval "local cda=(\$(echo '$cd' | sed 's/<space>/ /g'))"
    eval "$1=\$(echo -n ${cda[*]})"
  else
    eval "local cda=(\$(echo '$cd' | sed 's/<space>/ /g'))"
    eval "local cca=(\$(echo '$cc' | sed 's/<space>/ /g'))"
    local ca
    local ii=0
    for parac in ${cca[@]};do
      local flagC=0
      local index=0
      for parad in ${cda[@]};do
        if [ "$parad" == "$parac" ];then
          flagC=1
        else
          local parad_prefix=$(echo $parad | awk -F "=" '{printf $1}')
          local parac_prefix=$(echo $parac | awk -F "=" '{printf $1}')
          local parac_suffix=$(echo $parac | awk -F "=" '{printf $2}')
          if [ "$parad_prefix" == "$parac_prefix" ];then
            eval "cda[$index]='$parac'"
            [ "$parac_suffix"x == "!"x ] && eval "cda[$index]=''"
            flagC=1
          fi
        fi
        index=$(($index+1))
      done
      if [ $flagC -eq 0 ];then
        eval "ca[$ii]='$parac'"
      fi
    done
    eval "$1=\$(echo -n ${cda[*]}; echo -n ' '; echo -n ${ca[*]})"
  fi
}

##Prepare compilation
#Prepare directory function
# two parameters: $1:<a string of necessory directory path which separated by a whitespace>
#             and $2:<backup_or_not>
function prepareDir(){
  [ -z "$1" ] && eval "infoe 'err' 'Internal error.'" && exit 1
  [ -z "$2" ] && eval "infoe 'err' 'Internal error.'" && exit 1
  eval "local dirArray=($1)"
  for dirName in ${dirArray[@]};do
    eval "mkdir -p $dirName"
    eval "fileLine=\$(ls -1a $dirName | wc -l)"
    if [ $fileLine -gt 2 ];then
      if [ $2 -eq 1 ];then
        eval "infoe 'info' 'Moving old config file $dirName to $dirName$nowDate'"
        eval "mv $dirName $dirName$nowDate"
        eval "mkdir -p $dirName"
      else
        eval "infoe 'warn' 'Directory $dirName is not empty. For a clean installation, continue will remove all files in this directory.'"
        choiceyn 'continue?[y/n]' 'warn' 'You confirmed, go on..'
        local rmConfirm=$dirName'/*'
        [ "$rmConfirm"x == "/*"x ] && eval "infoe 'err' 'Dangerous directories will be removed! Abort.'" && exit 1
        eval "countDown '\e[1;31mWill process command: rm -rf $rmConfirm \e[0m' 5"
        eval "rm -rf $rmConfirm"
      fi
    fi
  done
}

#Last position which setting variables
debug=${c_debug:-1}
verifyes=1
confirmstep=1
nowDate=$(date '+%Y%m%d%H%M')
soft_prefix_list=('nginx' 'php' 'openssl' 'ctnginx')
[ "$c_soft_prefix_list"x != ""x ] && soft_prefix_list=($(echo ${c_soft_prefix_list[@]}))
[ "$nginx_install_dir"x == ""x ] && nginx_install_dir=$install_dir"/nginx"
[ "$php_install_dir"x == ""x ] && php_install_dir=$install_dir"/php"
[ "$nginx_conf_dir"x == ""x ] && nginx_conf_dir=$conf_dir"/nginx"
[ "$php_conf_dir"x == ""x ] && php_conf_dir=$conf_dir"/php"
processors=$(cat /proc/cpuinfo | grep '^processor' | wc -l)
j=$(($processors+1))
if [ -n $c_j ];then
  [ "$c_j"x == "0"x ] && eval "infoe 'err' 'Invalid value of c_j' 1" && exit 1
  [[ "$c_j" =~ [0-9]{1,2} ]] && j=$c_j
fi

##parse main script parameters --start--
function showHelp(){
  echo
  echo "  -h              show help information"
  echo
  echo "  -e              [necessory or choice -r] new installation"
  echo "                   ( will remove all files in $<software_name_prefix>[_install_dir|_conf_dir] )"
  echo "  -r              [necessory or choice -e] reinstallation or upgrade"
  echo "                   ( will remove all files in $<software_name_prefix>_install_dir )"
  echo "  -y              skip confirm step ( choice all y )"
  echo "  -j <jobs>       how many jobs to run parallelly when making [1-99, default is logical processor's counts + 1]"
  echo "  -v <level>      verbose mode, 0:no original command output; 1:no stdout from original command; 2:show all output"
  echo "  -n              no verified with asc file (not recommended)"
  echo "  -x <host:port>  http proxy"
  echo "  -s <dir>        set which directory to download source file [src_dir=<dir>]"
  echo "  -d <dir>        set the base installation directory [install_dir=<dir>]"
  echo "  -c <dir>        set the base configuration directory [conf_dir=<dir>]"
  echo
  echo "  Other configuration need to be set in this script file."
  echo "  Parameters set in terminal will override the configuration in this file."
  echo
}
if [[ "$@" =~ ^- ]];then
  while getopts ":ernyhv:s:d:c:x:j:" opt;do
    case "$opt" in
      h)
        showHelp && exit
        ;;
      e)
        installStatus='new'
        ;;
      r)
        installStatus='old'
        ;;
      y)
        eval "infoe 'info' 'No confirmation step.' 1"
        confirmstep=0
        ;;
      v)
        [ "$OPTARG"x == "0"x ] && debug=0
        [ "$OPTARG"x == "1"x ] && debug=1
        [ "$OPTARG"x == "2"x ] && debug=2
        ;;
      n)
        verifyes=0
        ;;
      j)
        [ "$OPTARG"x == "0"x ] && eval "infoe 'err' 'Invalid parameter' 1" && showHelp && exit 1
        [[ "$OPTARG" =~ [0-9]{1,2} ]] && j=$OPTARG
        ;;
      s)
        src_dir="$OPTARG"
        ;;
      d)
        install_dir="$OPTARG"
        ;;
      c)
        conf_dir="$OPTARG"
        ;;
      x)
        http_proxy="$OPTARG"
        ;;
      *)
        eval "infoe 'warn' 'invalid parameter' 1"
        showHelp && exit 1
    esac
  done
else
  eval "infoe 'warn' 'at least one parameter' 1"
  showHelp && exit 1
fi
[ -z $installStatus ] && eval "infoe 'warn' 'at least one of -r, -e'" && showHelp && exit 1
##parse main script parameters --start--

#Debug or not
main_out_put='/dev/null'
err_out_put='/dev/stderr'
[ $debug -eq 0 ] && main_out_put='/dev/null' && err_out_put='/dev/null'
[ $debug -eq 1 ] && main_out_put='/dev/null' && err_out_put='/dev/stderr'
[ $debug -eq 2 ] && main_out_put='/dev/stdout' && err_out_put='/dev/stderr'

##Prepare directories
if [ "$installStatus"x == "old"x ];then
  eval "prepareDir '$nginx_install_dir $php_install_dir $run_dir' 0"
  eval "prepareDir '$nginx_conf_dir $php_conf_dir' 1"
else
  true
  eval "prepareDir '$nginx_install_dir $php_install_dir $nginx_conf_dir $php_conf_dir $run_dir' 0"
fi

#Configuration confirm function
# one parameter: <software_name_prefix>
function confConfirm(){
  local src=$1'_source'
  local asc=$1'_source_asc'
  local key=$1'_source_asc_public_key'
  local key_id=$1'_source_asc_public_key_id'
  local key_uid=$1'_source_asc_public_key_uid'
  eval "echo -e '  $src: \e[1m'\$$src'\e[0m'"
  if [ $verifyes -eq 1 ];then
    eval "echo -e '  $asc: \e[1m'\$$asc'\e[0m'"
    eval "echo -e '  $key: \e[1m'\$$key'\e[0m'"
    eval "echo -e '  $key_id: \e[1m'\$$key_id'\e[0m'"
    eval "echo -e '  $key_uid: \e[1m'\$$key_uid'\e[0m'"
    echo
  fi
}

#Unpack tarball to source directory, need [head], [file], [awk], [tar], [bzip2], [gzip], [xz]
# three paramenters: $1:<package_name>, $2:<package_dir> and $3:<software_name_prefix>
function unPack(){
  pwdCheck 'src_dir'
  eval "type=\$(file --mime-type $1)"
  type=$(echo "$type" | awk -F ': ' '{printf $2}')
  case "$type" in
    application/x-gzip)
      local tarPara='-z'
      ;;
    application/x-bzip2)
      local tarPara='-j'
      ;;
    application/x-xz)
      local tarPara='-J'
      ;;
    *)
      eval "infoe 'err' 'Unknown file type $type of file $1'"
      exit 1
  esac
  eval "local dir0=\$(tar $tarPara -tf $1 | head -n 1 | awk -F '/' '{printf \$1}')"
  eval "local dir1=\$(tar $tarPara -tf $1 | tail -n 1 | awk -F '/' '{printf \$1}')"
  if [ "$dir0"x == "$dir1"x ];then
    eval "$2='$(pwd)/$dir0'"
    eval "infoe 'info' 'variable $2 set to '\$$2"
    eval "infoe 'info' 'unpacking $1 to $(pwd)/$dir0 ..'"
    eval "tar $tarPara  -xvf $1 > $main_out_put 2> $err_out_put" 
  else
    eval "$2='$(pwd)/$3'"
    eval "infoe 'info' 'variable $2 set to '\$$2"
    eval "infoe 'info' 'unpacking $1 to $(pwd)/$3 ..'"
    eval "tar $tarPara  -C $3 -xvf $1 > $main_out_put 2> $err_out_put" 
  fi
  [ $? -ne 0 ] && eval "infoe 'err' 'Unpacking package $1 error.'" && exit 1
}

#Loop function for name prefix
# two parameters: $1:<exec_function_or_cmd> and $2:<exec_function_or_cmd_parameters>
function prefixLoop(){
  for prefix in ${soft_prefix_list[@]};do
    case "$1" in
      initParaTarDir)
        local pkgName_pname=$prefix'_source_tar'
        local pkgDir_pname=$prefix'_source_dir'
        eval "$pkgName_pname=''"
        eval "$pkgDir_pname=''"
        ;;
      confConfirm)
        eval "confConfirm $prefix"
        ;;
      dl)
        local pkgName_pname=$prefix'_source_tar'
        local pkgUrl_pname=$prefix'_source'
        eval "$pkgName_pname=\$(parseUrlPkg \$$pkgUrl_pname)"
        eval "[ -z \$$pkgName_pname ] && $pkgName_pname=$prefix'.tar.gz'"
        eval "dl \$$pkgUrl_pname \$$pkgName_pname"
        ;;
      gpgCheck)
        local pkgName_pname=$prefix'_source_tar'
        eval "gpgCheck '$prefix' \$$pkgName_pname"
        ;;
      unPack)
        local pkgName_pname=$prefix'_source_tar'
        local pkgDir_pname=$prefix'_source_dir'
        eval "unPack \$$pkgName_pname $pkgDir_pname $prefix"
        ;;
    esac
  done
}

#Confirm and countdown
echo
echo "Here is the setting configurations, please confirm:"
[ "$installStatus"x == "new"x ] && echo '  New installation process.'
[ "$installStatus"x == "old"x ] && echo '  Reinstallation process.'
echo
[ "$http_proxy"x != ""x ] && echo -e "  Use HTTP Proxy: \e[1m$http_proxy\e[0m"
[ $verifyes -eq 0 ] && eval "infoe 'warn' 'No verification for souce file tarball' 1"
echo -e "  Source file workdir: \e[1m$src_dir\e[0m"
echo -e "  Installation dir: \e[1m$install_dir\e[0m"
echo -e "  Parallel jobs of make: \e[1m$j\e[0m"
echo -e "  Verbose mode: \e[1m$debug\e[0m"
echo
prefixLoop 'confConfirm'
eval "echo 'Packages installed by yum ( need epel-release ): $necessoryPackages'" | sed 's/\s\+/ /g' | sed 's/^/  /'
echo
choiceyn 'Are these correct?[y/n]' 'info' ''
countDown "You confirmed, go on.." 3
#Install necessory packages and databases(mariadb-server)
eval "infoe 'info' 'Install necessory packages by yum, please waiting.. '"
eval "yum install -y epel-release > $main_out_put 2>$err_out_put && yum clean all > $main_out_put 2>$err_out_put" && \
eval "yum update -y > $main_out_put 2>$err_out_put" && \
eval "yum install -y $necessoryPackages > $main_out_put 2>$err_out_put"
#Initialize some file name variables
prefixLoop 'initParaTarDir'
[ $? -ne 0 ] && exit 1
#Download packages
echo
prefixLoop 'dl'
[ $? -ne 0 ] && exit 1
#Verify packages
[ $verifyes -eq 1 ] && prefixLoop 'gpgCheck'
[ $? -ne 0 ] && exit 1
#Unpack tarball
prefixLoop 'unPack'
nginxConfFunc && phpConfFunc
confCompare 'nginx_compile_conf' 'c_nginx_compile_conf'
confCompare 'php_compile_conf' 'c_php_compile_conf'
echo
eval "echo '  Nginx compile configurations: $nginx_compile_conf'"
echo
eval "echo '  PHP compile configurations: $php_compile_conf'"
echo
choiceyn 'Are these correct?[y/n]' 'info' ''
countDown "You confirmed, go on.." 3

##Compilation Process
#compilation function
# one parameter: <sotfware_name_prefix>
function compile(){
  eval "infoe '' 'Begin compiling $1'"
  eval "local source_dir_pname=$1'_source_dir'"
  eval "local conf_pname=$1'_compile_conf'"
  local source_dir=$(eval "echo \$$source_dir_pname")
  local conf=$(eval "echo \$$conf_pname" | sed 's/\s/<space>/g')
  conf=$(echo $conf | sed 's/<space>/ /g')
  eval "infoe 'info' 'Entering directory -- $source_dir'"
  eval "cd $source_dir" || { eval "infoe 'err' 'Cannot enter into $source_dir'"; exit 1; }
  eval "infoe 'info' 'Configuring...'"
  eval "\$(./configure $conf > $main_out_put 2>$err_out_put)" || { eval "infoe 'err' 'Compilied failed [./configure $conf > $main_out_put 2>$err_out_put]'"; exit 1; }
  eval "infoe 'info' 'Configuration finished.'"
  eval "infoe 'info' 'Making ( $j job$([ $j -gt 1 ] && echo 's') parallelly )...'"
  eval "\$(make -j$j > $main_out_put 2>$err_out_put)" || { eval "infoe 'err' 'Make failed'"; exit 1; }
  eval "infoe 'info' 'Making finished.'"
  eval "infoe 'info' 'Make installing...'"
  eval "\$(make install > $main_out_put 2>$err_out_put)" || { eval "infoe 'err' 'Make failed'"; exit 1; }
  eval "infoe 'info' 'Installation finished.'"
  eval "infoe 'info' 'Package $1 compilation finished.'"
}
compile 'nginx'
compile 'php'

##Configuration for nginx and php configure file
#Stupid script below :(
tmp_conf_flag=(0 0)
eval "[ -f $nginx_conf_dir/nginx.conf ] && tmp_conf_flag[0]=1"
if [ ${tmp_conf_flag[0]} -eq 0 ];then
  [ -f "$nginx_conf_dir/nginx.conf.default" ] && \
  eval "infoe 'info' 'rename $nginx_conf_dir/nginx.conf.default to $nginx_conf_dir/nginx.conf'" && \
  eval "mv $nginx_conf_dir/nginx.conf.default $nginx_conf_dir/nginx.conf > $main_out_put 2> $err_out_put" && tmp_conf_flag[0]=1
  [ $? -eq 0 ] && eval "infoe 'info' 'renamed'" || eval "infoe 'warn' 'rename failed, you should check it later.'" 
fi
eval "[ -f $php_conf_dir/php-fpm.conf ] && tmp_conf_flag[1]=1"
if [ ${tmp_conf_flag[1]} -eq 0 ];then
  [ -f "$php_conf_dir/php-fpm.conf.default" ] && \
  eval "infoe 'info' 'rename $php_conf_dir/php-fpm.conf.default to $php_conf_dir/php-fpm.conf'" && \
  eval "mv $php_conf_dir/php-fpm.conf.default $php_conf_dir/php-fpm.conf > $main_out_put 2> $err_out_put" && tmp_conf_flag[1]=1
  [ $? -eq 0 ] && eval "infoe 'info' 'renamed'" || eval "infoe 'warn' 'rename failed, you should check it later.'" 
fi
if [ ! -f "$php_conf_dir/php-fpm.d/www.conf" ];then
  if [ ! -f "$php_conf_dir/php-fpm.d/www.conf.default" ];then
    eval "infoe 'warn' 'has no file $php_conf_dir/php-fpm.d/www.conf.default or $php_conf_dir/php-fpm.d/www.conf, you need to create it manually.'"
  else
    eval "infoe 'info' 'rename $php_conf_dir/php-fpm.d/www.conf.default to $php_conf_dir/php-fpm.d/www.conf'" && \
    eval "mv $php_conf_dir/php-fpm.d/www.conf.default $php_conf_dir/php-fpm.d/www.conf > $main_out_put 2> $err_out_put"
    [ $? -eq 0 ] && eval "infoe 'info' 'renamed'" || eval "infoe 'warn' 'rename failed, you should check it later.'" 
  fi
fi

[ ${tmp_conf_flag[0]} -eq 1 ] && \
  eval "infoe 'info' 'changing user, group, pid settings to $nginx_user, $nginx_group and $run_dir/nginx.pid in configure file $nginx_conf_dir/nginx.conf'" && \
  eval "sed -i.sed -e 's/^#user\s\+nobody\;/user  $nginx_user $nginx_group;/' -e 's#^\#pid\s\+logs/nginx.pid\;#pid  $run_dir/nginx.pid;#' $nginx_conf_dir/nginx.conf"
  [ $? -eq 0 ] && eval "infoe 'info' 'modified'" || eval "infoe 'warn' 'modify failed, you should check it later.'" 
[ ${tmp_conf_flag[1]} -eq 1 ] && \
  eval "infoe 'info' 'changing pid setting to $run_dir/php-fpm.pid in configure file $php_conf_dir/php-fpm.conf'" && \
  eval "sed -i.sed 's#^\;pid\s\+=\s\+run/php-fpm.pid#pid = $run_dir/php-fpm.pid#' $php_conf_dir/php-fpm.conf"
  [ $? -eq 0 ] && eval "infoe 'info' 'modified'" || eval "infoe 'warn' 'modify failed, you should check it later.'" 

#Generate systemd service file in /lib/systemd/system directory.
generateNginxSystemdServiceFile
eval "cat /lib/systemd/system/nginx.service > $main_out_put 2>$err_out_put"
generatePhpFpmSystemdServiceFile
eval "cat /lib/systemd/system/php-fpm.service > $main_out_put 2>$err_out_put"

#Create users and group
eval "groupadd $nginx_group"
[ $? -eq 0 ] && eval "infoe 'info' 'Group $nginx_group created'" || eval "infoe 'warn' 'Group $nginx_group created failed, you should check it later.'" 
[ "$nginx_group"x != "$php_group"x ] && \
  { eval "groupadd $php_group" && eval "infoe 'info' 'Group $php_group created'" || eval "infoe 'warn' 'Group $php_group created failed, you should check it later.'"; }
eval "useradd -g $nginx_group -s /usr/sbin/nologin -M $nginx_user"
[ $? -eq 0 ] && eval "infoe 'info' 'User $nginx_user created'" || eval "infoe 'warn' 'User $nginx_user created failed, you should check it later.'" 
eval "useradd -g $php_group -s /usr/sbin/nologin -M $php_user"
[ $? -eq 0 ] && eval "infoe 'info' 'User $php_user created'" || eval "infoe 'warn' 'User $php_user created failed, you should check it later.'" 

#Enable Nginx and PHP-FPM at startup
eval "systemctl enable nginx > $main_out_put 2> $err_out_put" && eval "infoe 'info' 'Nginx is enabled at startup'"
eval "systemctl enable php-fpm > $main_out_put 2> $err_out_put" && eval "infoe 'info' 'PHP-FPM is enabled at startup'"

echo 
echo 
eval "infoe 'info' 'FINISHED.' 1"
echo 


