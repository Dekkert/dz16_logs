## Lesson24- Сбор и анализ логов

### Задание:  
1. В Vagrant разворачиваем 2 виртуальные машины web и log
2. на web настраиваем nginx
3. на log настраиваем центральный лог сервер на любой системе на выбор
journald;
rsyslog;
elk.
4. настраиваем аудит, следящий за изменением конфигов nginx 

Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.

### Выполнение
Листинг Vagrantfile 

192.168.56.10 - nginx
192.168.56.15 - log

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end

  config.vm.define "web" do |web|
    web.vm.network "private_network", ip: "192.168.56.10"
    web.vm.hostname = "web"
    web.vm.provision "shell", path: "web.sh"
  end

  config.vm.define "log" do |log|
    log.vm.network "private_network", ip: "192.168.56.15"
    log.vm.hostname = "log"
    log.vm.provision "shell", path: "log.sh"
  end

end
```
На log отредактируем /etc/rsyslog.conf .

```
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

.
.
.
.

$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~

```

Перезапускаем syslog:
```
systemctl restart rsyslog
```

Проверяем открытые порты:

```
ss -tulpn | grep 514
udp    UNCONN     0      0         *:514                   *:*                   users:(("rsyslogd",pid=3444,fd=3))
udp    UNCONN     0      0      [::]:514                [::]:*                   users:(("rsyslogd",pid=3444,fd=4))
tcp    LISTEN     0      25        *:514                   *:*                   users:(("rsyslogd",pid=3444,fd=5))
tcp    LISTEN     0      25     [::]:514                [::]:*                   users:(("rsyslogd",pid=3444,fd=6))
```


На web редактируем /etc/nginx/nginx.conf:

```
    access_log syslog:server=192.168.56.15:514,tag=nginx_access main;
    error_log syslog:server=192.168.56.15:514,tag=nginx_error notice;
    access_log syslog:server=192.168.56.15:514,tag=nginx_access,severity=info combined;

```

Проверяем и перезапускаем nginx:

```
nginx -t
systemctl restart nginx

```

Удаляем картинку и проверяем сервер логов:

```
rm /usr/share/nginx/html/img/header-background.png
```

```
[root@log rsyslog]# cat /var/log/rsyslog/web/nginx_access.log 
May 28 21:21:54 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:54 +0300] "GET / HTTP/1.1" 200 4833 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:54 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:54 +0300] "GET / HTTP/1.1" 200 4833 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/centos-logo.png HTTP/1.1" 200 3030 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/centos-logo.png HTTP/1.1" 200 3030 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/html-background.png HTTP/1.1" 200 1801 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/html-background.png HTTP/1.1" 200 1801 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/header-background.png HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/header-background.png HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /favicon.ico HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /favicon.ico HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
[root@log rsyslog]# cat /var/log/rsyslog/web/nginx_access.log 
May 28 21:21:54 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:54 +0300] "GET / HTTP/1.1" 200 4833 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:54 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:54 +0300] "GET / HTTP/1.1" 200 4833 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/centos-logo.png HTTP/1.1" 200 3030 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/centos-logo.png HTTP/1.1" 200 3030 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/html-background.png HTTP/1.1" 200 1801 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/html-background.png HTTP/1.1" 200 1801 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/header-background.png HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /img/header-background.png HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /favicon.ico HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0" "-"
May 28 21:21:55 web nginx_access: 192.168.56.1 - - [28/May/2023:21:21:55 +0300] "GET /favicon.ico HTTP/1.1" 404 3650 "http://192.168.56.10/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
[root@log rsyslog]# cat /var/log/rsyslog/web/nginx_error.log 
May 28 21:21:55 web nginx_error: 2023/05/28 21:21:55 [error] 3653#3653: *1 open() "/usr/share/nginx/html/img/header-background.png" failed (2: No such file or directory), client: 192.168.56.1, server: _, request: "GET /img/header-background.png HTTP/1.1", host: "192.168.56.10", referrer: "http://192.168.56.10/"
May 28 21:21:55 web nginx_error: 2023/05/28 21:21:55 [error] 3653#3653: *1 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.56.1, server: _, request: "GET /favicon.ico HTTP/1.1", host: "192.168.56.10", referrer: "http://192.168.56.10/"

```

#### Настраиваем аудит 

```
cat /etc/audit/rules.d/audit.rules
## First rule - delete all
-D

## Increase the buffers to survive stress events.
## Make this bigger for busy systems
-b 8192

## Set failure mode to syslog
-f 1

-w /etc/nginx/nginx.conf -p wa -k web_config_changed
-w /etc/nginx/conf.d/ -p wa -k web_config_changed
```

Перезапускаем службу auditd:

```
service auditd restart
```
Вносим изменения в nginx.conf:

```
[root@web vagrant]# ausearch -f /etc/nginx/nginx.conf
----
time->Sun May 28 21:27:12 2023
type=CONFIG_CHANGE msg=audit(1685298432.926:1087): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
----
time->Sun May 28 21:27:12 2023
type=PROCTITLE msg=audit(1685298432.926:1088): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1685298432.926:1088): item=3 name="/etc/nginx/nginx.conf~" inode=749572 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1685298432.926:1088): item=2 name="/etc/nginx/nginx.conf" inode=749572 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1685298432.926:1088): item=1 name="/etc/nginx/" inode=85 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1685298432.926:1088): item=0 name="/etc/nginx/" inode=85 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1685298432.926:1088):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1685298432.926:1088): arch=c000003e syscall=82 success=yes exit=0 a0=1536a10 a1=1540110 a2=fffffffffffffe80 a3=7ffcc316a060 items=4 ppid=3575 pid=3721 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun May 28 21:27:12 2023
type=CONFIG_CHANGE msg=audit(1685298432.928:1089): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
----
time->Sun May 28 21:27:12 2023
type=PROCTITLE msg=audit(1685298432.928:1090): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1685298432.928:1090): item=1 name="/etc/nginx/nginx.conf" inode=749574 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1685298432.928:1090): item=0 name="/etc/nginx/" inode=85 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1685298432.928:1090):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1685298432.928:1090): arch=c000003e syscall=2 success=yes exit=3 a0=1536a10 a1=241 a2=1a4 a3=0 items=2 ppid=3575 pid=3721 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun May 28 21:27:12 2023
type=PROCTITLE msg=audit(1685298432.931:1091): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1685298432.931:1091): item=0 name="/etc/nginx/nginx.conf" inode=749574 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1685298432.931:1091):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1685298432.931:1091): arch=c000003e syscall=188 success=yes exit=0 a0=1536a10 a1=7f3a8b455f6a a2=1544d70 a3=24 items=1 ppid=3575 pid=3721 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun May 28 21:27:12 2023
type=PROCTITLE msg=audit(1685298432.931:1092): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1685298432.931:1092): item=0 name="/etc/nginx/nginx.conf" inode=749574 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1685298432.931:1092):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1685298432.931:1092): arch=c000003e syscall=90 success=yes exit=0 a0=1536a10 a1=81a4 a2=0 a3=24 items=1 ppid=3575 pid=3721 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun May 28 21:27:12 2023
type=PROCTITLE msg=audit(1685298432.931:1093): proctitle=7669002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1685298432.931:1093): item=0 name="/etc/nginx/nginx.conf" inode=749574 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1685298432.931:1093):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1685298432.931:1093): arch=c000003e syscall=188 success=yes exit=0 a0=1536a10 a1=7f3a8b00be2f a2=1544080 a3=1c items=1 ppid=3575 pid=3721 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"

```

#### Настройка пересылки логов аудита на удаленный сервер:

Устанавливаем плагин:

```
yum -y install audispd-plugins
```
Редактируем файлы на web(отредактированные файлы прилагаются в репозитории):

/etc/audit/rules.d/audit.rules
/etc/audisp/plugins.d/au-remote.conf
/etc/audisp/audisp-remote.conf

Редактируем файлы на log(отредактированные файлы прилагаются в репозитории):

/etc/audit/auditd.conf

меняем настройки в etc/nginx/nginx.conf и проверяем.

```
[root@log ~]# grep web /var/log/audit/audit.log 
node=web type=SYSCALL msg=audit(1685298952.235:1113): arch=c000003e syscall=268 success=yes exit=0 a0=ffffffffffffff9c a1=17fe420 a2=1ed a3=7ffc01150820 items=1 ppid=3575 pid=3872 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1685298952.235:1113):  cwd="/home/vagrant"
node=web type=PATH msg=audit(1685298952.235:1113): item=0 name="/etc/nginx/nginx.conf" inode=394503 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1685298952.235:1113): proctitle=63686D6F64002B78002F6574632F6E67696E782F6E67696E782E636F6E66

```



