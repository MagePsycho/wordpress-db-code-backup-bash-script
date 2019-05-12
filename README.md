# Bash Script: Backup Wordpress Code + Database

This utility script helps you to backup Wordpress code and database.   
You can either run the command manually or can automate it via cronjob.


## INSTALL
You can simply download the script file and give the executable permission.
```
curl -0 https://raw.githubusercontent.com/MagePsycho/wordpress-db-code-backup-bash-script/master/src/wp-db-code-backup.sh -o wp-backup.sh
chmod +x wp-backup.sh
```

To make it system wide command
```
sudo mv wp-backup.sh /usr/local/bin/wp-backup
```

## USAGE
### To display help
```
./wp-backup.sh --help
```

### To backup database only
```
./wp-backup.sh --type=db --src-dir=/path/to/wp/root --dest-dir=/path/to/destination
```

### To backup code only
```
./wp-backup.sh --type=code --skip-uploads --src-dir=/path/to/wp/root --dest-dir=/path/to/destination
```
- `--skip-uploads` option excludes `wp-content/uploads` folder

### To backup code + database
```
./wp-backup.sh --type=all --skip-uploads --src-dir=/path/to/wp/root --dest-dir=/path/to/destination
```

*You can omit `--src-dir` option if you are running the script as system-wide command from root folder of wordpress*

### To schedule backup via Cron
If you want to schedule via Cron, just add the following line in your Crontab entry `crontab -e`
```
0 0 * * * /path/to/wp-backup.sh --type=all --skip-uploads --src-dir=/path/to/wp/root --dest-dir=/path/to/destination > /dev/null 2>&1
```
`0 0 * * *` expression means the command will run run at every midnight.

## Screenshots
![WordpressBackup Help](https://raw.githubusercontent.com/MagePsycho/wordpress-db-code-backup-bash-script/master/docs/wordpress-backup-script-help.png "Mage2Backup Help")
1. Screentshot - WordpressBackup Help

## TO-DOS
- Rotation for backups
- Enable remote backups
    - S3
    - Google Drive
    - Dropbox
