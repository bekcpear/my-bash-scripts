## 一个用于生成可提高 HTTPS 安全性相关信息的脚本

**目前可生成的信息有**

1. 用于 Diffie–Hellman 密钥交换的参数文件，在 Nginx 配置文件下的参数名为 `ssl_dhparam`
2. 用于通过 TLS 扩展来启用证书透明度而需要获取的 Signed Certificate Timestamp 文件
3. 启用 HPKP 所需要的 Base64 编码格式的从每张证书中提取的 SPKI (Subject Public Key Information) 指纹

获取 1 和 3 会用到 `openssl`，默认指定了 `/usr/bin/openssl`，也可以打开脚本文件编辑为其它。

获取 2 时需要用到 go 来建可执行的 ct-submit 提交程序（会先下载 ct-submit 源码包到 /tmp 目录下，执行完且成功则会清理掉），请提前安装好 golang，其它都是很基本的工具了。

**使用方法很简单**，直接贴一个实际例子:

```
# 帮助信息
[23:45:53] root@mayfi ~ # ./GEN4AddlSectyOfSSLCert.sh help

  Usage: ./GEN4AddlSectyOfSSLCert.sh COMMAND [OPTIONS]

  COMMAND
    dhparam      generate a file of DH parameters
    sct          get Signed Certificate Timestamps
    hpkp         extra the Base64 encoded SPKI fingerprint

    help(-h)     show this help

  OPTIONS (for all)
    -f               force to override file when the file already exists
    -v <num>         verbose mode (default 1)
                       0: only script error
                       1: script info/error
                       2: 1's & command error
                       3: all
  OPTIONS (for dhparam)
    -o <path>        path of the generated file
    -b <num>         number of bits in to generate (default 2048)
  OPTIONS (for sct)
    -i <path>        path of the certificate chain file
    -o <path>        path of directory which store the SCTs files
  OPTION  (for hpkp)
    -i <path>        path of the certificate, can be used multiple times

# 生成 DH 参数文件
[23:45:57] root@mayfi ~ # ./GEN4AddlSectyOfSSLCert.sh dhparam -o /data/0/conf.d/forSec/dhparam.pem 
  [info 23:46:11 /root] Generating DHParam...
  [info 23:46:11 /root]   EXEC: read -n 1 -rep "override existing file /data/0/conf.d/forSec/dhparam.pem [y/n]? " yn > /dev/stdout 2> /dev/stderr
override existing file /data/0/conf.d/forSec/dhparam.pem [y/n]? y
  [info 23:46:12 /root]   EXEC: /usr/bin/openssl dhparam -outform PEM -out /data/0/conf.d/forSec/dhparam.pem 2048 > /dev/null 2> /dev/null
  [info 23:52:18 /root]   FILE: -rw-r--r--. 1 root root 424 May 25 23:52 /data/0/conf.d/forSec/dhparam.pem
  [info 23:52:18 /root] DHParam generated.

# 获取 Signed Certificate Timestamp，并重定向输出到文件
[23:52:18] root@mayfi ~ # ./GEN4AddlSectyOfSSLCert.sh sct -i /etc/letsencrypt/live/c.ume.ink/fullchain.pem -o /data/0/conf.d/forSec/scts
  [info 23:54:12 /root] Get SCTs...
  [info 23:54:12 /root]   EXEC: cd /tmp > /dev/null 2> /dev/null
  [info 23:54:12 /tmp] Download https://github.com/grahamedgecombe/ct-submit/archive/v1.1.2.tar.gz to ./ct-submit-1.1.2.tar.gz
  [info 23:54:12 /tmp]   EXEC: wget https://github.com/grahamedgecombe/ct-submit/archive/v1.1.2.tar.gz -O ./ct-submit-1.1.2.tar.gz > /dev/null 2> /dev/null
  [info 23:54:13 /tmp] verify ./ct-submit-1.1.2.tar.gz by sha256sum method
  [info 23:54:13 /tmp]   EXEC: echo f41702c86f4f1cb68274c0b3deed68016471dc443bd7f5665b5ae709e55d7af1  ./ct-submit-1.1.2.tar.gz | sha256sum -c --status > /dev/null 2> /dev/null
  [info 23:54:13 /tmp]   EXEC: tar -xf ./ct-submit-1.1.2.tar.gz > /dev/null 2> /dev/null
  [info 23:54:13 /tmp]   EXEC: cd ct-submit-1.1.2 > /dev/null 2> /dev/null
  [info 23:54:14 /tmp/ct-submit-1.1.2]   EXEC: go build . > /dev/null 2> /dev/null
  [info 23:54:15 /tmp/ct-submit-1.1.2]   EXEC: chmod +x ./ct-submit-1.1.2 > /dev/null 2> /dev/null
  [info 23:54:15 /tmp/ct-submit-1.1.2]   EXEC: read -n 1 -rep "override existing file /data/0/conf.d/forSec/scts/icarus.sct [y/n]? " yn > /dev/stdout 2> /dev/stderr
override existing file /data/0/conf.d/forSec/scts/icarus.sct [y/n]? y
  [info 23:54:17 /tmp/ct-submit-1.1.2]   EXEC: ./ct-submit-1.1.2 ct.googleapis.com/icarus </etc/letsencrypt/live/c.ume.ink/fullchain.pem > /data/0/conf.d/forSec/scts/icarus.sct 2> /dev/null
  [info 23:54:18 /tmp/ct-submit-1.1.2]   FILE: -rw-r--r--. 1 root root 118 May 25 23:54 /data/0/conf.d/forSec/scts/icarus.sct
  [info 23:54:18 /tmp/ct-submit-1.1.2]   EXEC: read -n 1 -rep "override existing file /data/0/conf.d/forSec/scts/rocketeer.sct [y/n]? " yn > /dev/stdout 2> /dev/stderr
override existing file /data/0/conf.d/forSec/scts/rocketeer.sct [y/n]? y
  [info 23:54:22 /tmp/ct-submit-1.1.2]   EXEC: ./ct-submit-1.1.2 ct.googleapis.com/rocketeer </etc/letsencrypt/live/c.ume.ink/fullchain.pem > /data/0/conf.d/forSec/scts/rocketeer.sct 2> /dev/null
  [info 23:54:24 /tmp/ct-submit-1.1.2]   FILE: -rw-r--r--. 1 root root 118 May 25 23:54 /data/0/conf.d/forSec/scts/rocketeer.sct
  [info 23:54:24 /tmp/ct-submit-1.1.2] SCTs got.
  [info 23:54:24 /tmp/ct-submit-1.1.2]   EXEC: cd /tmp > /dev/null 2> /dev/null
  [info 23:54:24 /tmp]   EXEC: rm -f ./ct-submit-1.1.2.tar.gz > /dev/null 2> /dev/null
  [info 23:54:24 /tmp]   EXEC: rm -rf ./ct-submit-1.1.2 > /dev/null 2> /dev/null

# 导出启用 HPKP 所需的证书 SPKI 指纹
[23:54:24] root@mayfi ~ # ./GEN4AddlSectyOfSSLCert.sh hpkp -i ./server.pem -i ./intermediate.pem -i ./lets-encrypt-x4-cross-signed.pem.txt 
  [info 23:54:49 /root] Extracting the base64 encoded information from the certificate...
  [info 23:54:49 /root] PIN-SHA256 of ./server.pem is:
  [info 23:54:49 /root]   KRaiQ1g4fSEOEUnqbaSucQ3LhWlExCsNAPAkzHkE5vA=
  [info 23:54:49 /root] PIN-SHA256 of ./intermediate.pem is:
  [info 23:54:49 /root]   YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=
  [info 23:54:49 /root] PIN-SHA256 of ./lets-encrypt-x4-cross-signed.pem.txt is:
  [info 23:54:49 /root]   sRHdihwgkaib1P1gxX8HFszlD+7/gTfNvuAybgLPNis=
  [info 23:54:49 /root] Base64 encoded information of the certificate has been extracted.
```

