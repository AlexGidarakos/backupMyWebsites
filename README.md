# backupMyWebsites
backupMyWebsites.sh is a Bash script for unattended local backups of multiple websites on a LEMP server. It's designed to run with root privileges from a daily cronjob and create daily, weekly and monthly backups of our websites.

For each website, a configuration file with a .conf extension must be created inside the conf.d subdirectory. See file conf.d/example.com.conf.README for an example configuration.

Dependencies: Bash, GNU coreutils, systemd, nginx, php5-fpm, rsync, mysqldump, gzip. With some modifications, it should work for other shells, init systems, Apache instead of nginx etc.

Tested on: Debian GNU/Linux 8.4 amd64

## Automatic MySQL/MariaDB login for root
You can store the root MySQL/MariaDB password in a special file:
```bash
# vi /root/.my.cnf
```

.my.cnf contents:
```
[client]
password = YOUR_ROOT_SQL_PASSWORD_HERE
```

Always secure this file:
```bash
# chmod 600 /root/.my.cnf
```

Now, when you run any MySQL/MariaDB command-line tools (mysql, mysqldump etc.) as root, you will be automatically logged in as root!

## Cronjob setup for root
Suppose you extracted the backupMyWebsites tar.gz file in "/opt/". First, give the script execute permissions:
```bash
# chmod +x /opt/backupMyWebsites/backupMyWebsites.sh
```

Now you can create a cronjob that will run every day at e.g. 3:30am with this one-liner:
```bash
# crontab -l | { cat; echo '30 3 * * * /opt/backupMyWebsites/backupMyWebsites.sh'; } | crontab -
```
