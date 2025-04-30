# ISPConfig - ACME Api Plugin

Allow users to create an api key to use dns auth for acme.sh/certbot/... for  [ISPCONFIG](https://ispconfig.com)

### !! Still in Beta/Testing !!
### !! Not Multiserver tested !!


## Features
- `System > Server Config > Your Server Name > TAB ACME (Plugin)`
- `DNS > Zones > Select Zone > TAB ACME (Plugin)`

- DNS Auth Plugin script for acme.sh ("helperscripts/acme.sh/dns_ispcapi.sh")
- DNS Auth Plugin script for certbot ("helperscripts/certbot/dns_ispcapi.sh")

## Installation

Update the ispconfig Database (dbispconfig):
```
ALTER TABLE `dns_soa` ADD COLUMN IF NOT EXISTS `plugin_acmeapi_key` VARCHAR(50) NULL;
```
On your server 
```bash
cd /tmp
git clone https://github.com/Nethan/ispconfig-acmeplugin.git
cd ispconfig-acmeplugin
# the ispconfig pluing
cp -Ri interface/lib/plugins/acmeapi_plugin /usr/local/ispconfig/interface/lib/plugins/
cp -i interface/lib/plugins/acmeapi_plugin.inc.php /usr/local/ispconfig/interface/lib/plugins/
chown ispconfig:ispconfig /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin.inc.php
chmod 640 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin.inc.php
chown -R ispconfig:ispconfig /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin
chmod -R 640 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin
chmod 750 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin
chmod 750 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin/templates
chmod 750 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin/lib
chmod 750 /usr/local/ispconfig/interface/lib/plugins/acmeapi_plugin/lib/lang



## the api itself - you can put it everywhere - default into the ispconfig installation
cp -i interface/web/remote/plugin_acmeapi.php /usr/local/ispconfig/interface/web/remote/
chown ispconfig:ispconfig /usr/local/ispconfig/interface/web/remote/plugin_acmeapi.php
chmod 640 /usr/local/ispconfig/interface/web/remote/plugin_acmeapi.php

rm -rf /tmp/ispconfig-acmeplugin
```

## Configuration

- Create a remote user with following permission `DNS zone function`, `Client function` and `DNS txt function` 
- Edit `/usr/local/ispconfig/interface/web/remote/plugin_acmeapi.php` and insert the created user/password. Edit the URL if necessary. 
- Config `System > Server Config > Your Server Name > TAB ACME (Plugin)` with your data and enable it.


# Use the Plugin
 - create a api key in your zone `DNS > Zones > Select Zone > TAB ACME (Plugin)`

!!! Logout and Login to get the plugin active !!!

## acme.sh
- Download the dns plugin script for acme.sh into /root/.acme.sh/dnsapi (if default installation)
```bash
cd /root/.acme.sh/dnsapi
wget https://raw.githubusercontent.com/Nethan/ispconfig-acmeplugin/refs/heads/master/helperscripts/acme.sh/dns_ispcapi.sh

# export the key and url (replace with your url and key)
export ISPCAPI_URL=https://yourserver.xx:8080/remote/plugin_acmeapi.php
export ISPCAPI_KEY=xxxxxxxxxxxxxxxxxxx

#Test a cert (staging) dnssleep to allow ispconfig to write the config and dns to propagate
acme.sh --issue --staging --debug 2 -d yourdomain.xx --dnssleep 70 --dns dns_ispcapi

#Create a real Cert
acme.sh --issue -d yourdomain.xx --dnssleep 70 --dns dns_ispcapi
acme.sh --issue -d vpn.yourdomain.xx -d yourdomain.xx --dnssleep 70 --dns dns_ispcapi

```

## certbot
- Download the dns plugin script for certbot into a folder (/usr/local/sbin as example)
```bash
cd /usr/local/sbin
wget https://raw.githubusercontent.com/Nethan/ispconfig-acmeplugin/refs/heads/master/helperscripts/certbot/dns_ispcapi.sh
chmod 700 /usr/local/sbin/dns_ispcapi.sh

# edit the `/usr/local/sbin/dns_ispcapi.sh` and enter the URL and the key
vi /usr/local/sbin/dns_ispcapi.sh 
#Test it
certbot --dry-run certonly --manual --manual-auth-hook "/usr/local/sbin/dns_ispcapi.sh auth"  --manual-cleanup-hook "/usr/local/sbin/dns_ispcapi.sh cleanup" --agree-tos --email xxx@yourdomain.xx --preferred-challenges=dns -d 'yourdomain.xx'
#Create a Cert (waits 70 second (for every SAN) for DNS propagate
certbot certonly --manual --manual-auth-hook "/usr/local/sbin/dns_ispcapi.sh auth"  --manual-cleanup-hook "/usr/local/sbin/dns_ispcapi.sh cleanup" --agree-tos --email xxx@yourdomain.xx --preferred-challenges=dns -d 'yourdomain.xx'
certbot certonly --manual --manual-auth-hook "/usr/local/sbin/dns_ispcapi.sh auth"  --manual-cleanup-hook "/usr/local/sbin/dns_ispcapi.sh cleanup" --agree-tos --email xxx@yourdomain.xx --preferred-challenges=dns -d 'yourdomain.xx' -d 'vpn.yourdomain.xx' -d 'mail.yourdomain.xx'

```
## Screenshot

![Admin](/screenshot/admin.jpg)

![User](/screenshot/user.jpg)


