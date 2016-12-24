这是一个在 CentOS 7 上使用源码编译安装 Nginx 和 PHP-FPM 的脚本。同时会使用 yum 进行安装数据库 Mariadb （数据库的配置和安装完全不参考下列说明）

## 几点说明

相关变量简单说明，详细请查阅脚本内注释（以下说明的都可以通过修改对应脚本文件内变量进行修改）
+ Nginx 下默认单独指定 openssl 和 nginx-ct 编译进去的
+ 所有源码包都可以使用对应的 asc 文件验证其完整性，也是默认要求的。默认已经提供了如下：
  1. ML 版本 nginx-1.11.7 的下载连接和对应 asc 文件连接以及相关公钥信息
  2. LTS 版本 openssl-1.0.2j 的下载连接和对应 asc 文件连接以及相关公钥信息
  3. nginx-ct v1.3.2 的下载连接和对应 asc 文件连接以及相关公钥信息
  4. Stable 版本 PHP 7.1.0 的下载连接和对应 asc 文件连接以及相关公钥信息
+ 默认源码下载使用工具 wget 并指定目录 `/opt/src` ，同时也是解压路径和验证文件下载路径
+ 默认指定安装路径是 `/opt/local/<software_name>` ，配置文件路径是 `/opt/conf/<software_name>`
+ 默认 PID 文件路径 `/opt/run/<software_name>.pid`
+ 脚本执行过程，默认将脚本内命令执行 stdout 重定向到 `/dev/null` ，提供脚本运行参数 `-v` 可以指定，或者修改脚本内 debug 变量持久设置：
  1. 0：只显示脚本本身提示信息，所有内置命令的 stderr 和 stdout 都重定向到 `/dev/null` （最清爽的执行界面，最下方提供完整执行日志）
  2. 1：（默认值）stdout 重定向到 `/dev/null`
  3. 2：显示全部信息（这样子可能会很难发现关键性警告/错误提示）
+ 默认编译时候并行运行任务数目为当前机器逻辑 CPU 数目加一，可以使用参数指定修改或者修改脚本内 c_j 变量
+ 默认 Nginx 执行用户为 nginx ，用户组 webService
+ 默认 PHP-FPM 执行用户为 php-fpm ，用户组 webService
+ 可以设置下载文件时是否使用代理，默认无代理
+ 默认编译参数统一贴在下面，不用修改默认变量，有单独的变量 c_<softwarename>_compile_conf 可供设置：
  + 当设置参数不同时，会在默认参数情况下添加
  + 当设置参数键相同，值不同时，会覆盖默认参数
  + 当需要取消默认参数时，使用格式 `--parametername=!` ，不管该参数是否可以设置值，只需要设置感叹号即可取消该默认参数。


脚本执行最开始，会使用 yum 工具安装编译所需要的包：
> bzip2 gzip xz wget gcc make re2c autoconf pcre-devel zlib-devel libxml2-devel openssl-devel bzip2-devel libjpeg-devel libpng-devel gettext-devel freetype-devel libmcrypt-devel libcurl-devel bison-devel bison

编译结束后，默认生成 systemd 的服务文件，并配置好相关设置以及启用开机启动，直接运行 `systemctl start <software_name>` 即可运行程序（当然其他环境参数配置需要额外设置）

编译结束后，也同样会创建相应的用户和组，不创建用户文件夹， shell 设定为 `/usr/sbin/nologin`

## 脚本执行参数说明
```
  -h              显示帮助提示（英文的，为了避免字符串问题所有脚本内注释和提示都是英文）
  -e              安装模式一，情景是新机器安装时，将删除指定安装路径以及指定配置路径下对应的 PHP 和 Nginx 的文件 （默认的日志文件也在安装目录下，脚本内没有可以设置修改的项目）
  -r              安装模式二，情景是重新安装或者升级时，将删除指定安装路径下对应的 PHP 和 Nginx 的文件，不会删除配置文件
                  两个模式必须选择其一，否则无法继续执行
  -y              默认执行的时候会有几个步骤需要确认后方才可以执行，比如上述的删除动作，提供这个参数后，则不会有任何选择直接执行
  -j <jobs>       设定执行编译过程时同时运行任务数目，默认时当前 CPU 核心数 + 1 ，可以接受的参数值是 1-99
  -v <level>      日志在终端显示的详细程度，详细看上述已经有说明
  -n              不对下载的源码包进行签名认证，默认都是需要认证的，如果你比较懒找对应的签名文件下载连接和公钥信息，可以选择这个，不推荐
  -x <host:port>  下载时指定 HTTP 代理
  -s <dir>        除了可以在脚本内设置源码包下载路径，也可以在这里设置
  -d <dir>        除了可以在脚本内设置软件安装[基本的]路径，也可以在这里设置
  -c <dir>        除了可以在脚本内设置软件配置文件[基本的]路径，也可以在这里设置
                  在这里，[基本的]意思是非单独 Nginx 或者 PHP 的软件安装/配置路径，而是它们的总体路径，如许单独设置，脚本内提供了单独的自定义变量
                  比如：Nginx 的安装路径为 <当前设定的基本路径>/nginx
```

## 默认编译参数
Nginx 的默认编译参数：

```
--prefix=/opt/local/nginx
--conf-path=opt/conf/nginx'/nginx.conf'
--user=nginx
--group=webService
--with-http_realip_module
--with-http_sub_module
--with-http_gzip_static_module
--with-http_stub_status_module
--with-openssl=$openssl_source_dir #这个变量会在解压 openssl 后自动设定
--with-http_ssl_module
--with-http_v2_module
--add-module=$ctnginx_source_dir #这个变量会在解压 nginx-ct 后自动设定
--with-debug
--with-pcre
```

PHP 的默认编译参数：
```
--prefix=/opt/local/php
--sysconfdir=/opt/conf/php
--enable-fpm
--with-fpm-user=php-fpm
--with-fpm-group=webService
--with-mysqli
--with-libxml-dir
--with-gd
--with-jpeg-dir
--with-png-dir
--with-freetype-dir
--with-iconv-dir
--with-zlib-dir
--with-mcrypt
--with-curl
--with-pear
--with-gettext
--enable-bcmath
--enable-sockets
--enable-soap
--enable-gd-native-ttf
--enable-ftp
--enable-exif
--enable-tokenizer
--with-pdo-mysql
--enable-mbstring
--with-openssl
```

## 一个完整的全新安装日志记录（-v 0 下）：


