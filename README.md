# backupMyWebsites

backupMyWebsites.sh is a BASH script for unattended backups of multiple websites on a LEMP server. It's designed to run with root privileges from a daily cronjob and create daily, weekly and monthly backups of our websites.

For each website, a configuration file with a .conf extension must be created inside the conf.d subdirectory. See file conf.d/example.com.conf.README for an example configuration.

Dependencies: BASH, GNU coreutils, systemd, nginx, php5-fpm, rsync, mysqldump, gzip. With some modifications, it should work for other shells, init systems, Apache instead of nginx etc.

Tested on: Debian GNU/Linux 8.4 amd64

## Example of cronjob setup for root

Suppose you extracted the backupMyWebsites tar.gz file in "/opt/". First, give the script execute permissions:
```bash
# chmod +x /opt/backupMySites/backupMySites.sh
```

Now you can create a cronjob that will run every day at e.g. 3:30am with this one-liner:
```bash
# crontab -l | { cat; echo '30 3 * * * /opt/backupMySites/backupMySites.sh'; } | crontab -
```
