#!/bin/bash
# Add site script
#
# Params: domainname.com dbname dbuser dbpasswd
#
# Version 1.2 - April 16th, 2014
#

source /var/git/server-project/lib/svr-proj-libs.sh

GIT_TEMPLATE_PATH="/var/git/server-project/vhost-template";
TEMPLATE_PATH="$VHOST_PATH/vhost-template";
LOG_PATH="/var/log/httpd";
# Get IP for eth0
IP=`ifconfig eth0 | grep inet | grep -v inet6 | awk -F: '{ print $2 }' | awk '{ print $1 }'`;

ALL_IPS="";
ALL_INTERNAL_IPS="";
ALL_INTERNAL_WEB_IPS="";
SSL="";
HTTP_IPPORTS="";
HTTPS_IPPORTS="";
ALL_INTERNAL_WEB_IPS="";
PUB_HTTPS_WEB_IPPORTS="";
INT_HTTPS_WEB_IPPORTS="";
PUB_HTTP_WEB_IPPORTS="";
INT_HTTP_WEB_IPPORTS="";

# TODO: Prompt for SSL redirect
# TODO: prompt for git path

function display_req_parms {
	echo;
	echo "######################################################################################";
	echo "You must supply the domain and optionally the DB name, DB user and DB pass";
	echo "Example: ";
	echo "    $0 domainname.com dbname dbuser dbpass";
	echo "######################################################################################";
	echo;
	exit 1;
}

function remove_domain_www {
	echo;
	echo 'It is not necessary to append www to the domain!';
	echo '  Removing...';
	echo;
	DOMAIN=`echo $DOMAIN | sed 's/^www\.//'`;
	SAFEDOMAIN=`echo $DOMAIN | sed 's/\./-/g'`;
}

root_check;
check_which_server;

# Make sure params were supplied
if [ -z "$1" ]; then
	# Domain name was not supplied
	display_req_parms;
fi;

# Lowercase domain name
DOMAIN=`echo "$1" | tr '[A-Z]' '[a-z]'`;
# Domain name with dashes removed for dev/qa environments
SAFEDOMAIN=`echo $DOMAIN | sed 's/\./-/g'`;

SITE_PATH="$VHOST_PATH/$DOMAIN";
VHOST_SYMLINK="/etc/httpd/conf.d/vhost-$DOMAIN.conf";
CONF_FILE="$SITE_PATH/config/$VHOST_CONF"

# Check to see if domain has www on it and remove it if so
echo "$DOMAIN" | grep -e "^www." &> /dev/null && remove_domain_www;

# DB Credentials
# Max length for DB name in MySQL is 64 chars
if [ -z "$2" ]; then
	# Replace dots in domain name with - & Truncate to first 64 chars
	# TODO: Strip out invalid characters!
	DB_NAME=`echo ${DOMAIN:0:63} | sed 's/[\.-]//g'`;
else
	# Use supplied DB name
	DB_NAME="$2";
fi;

# Max username length is 16 chars...
if [ -z "$3" ]; then
	# Generate a DB Username
	# Remove dots and dashes and only grab first 16 chars
	DB_USER=`echo ${DOMAIN:0:15} | sed 's/[\.-]//g'`;
else
	# Use provided DB Username
	DB_USER="$3";
fi;

if [ -z "$4" ]; then
	# Generate random password for DB
	DB_PASSWD=`openssl rand -base64 6`;
else
	# Use the DB password supplied
	DB_PASSWD="$4";
fi;
DB_HOST="127.0.0.1";

# Check to make sure auto-generated and/or user supplied values were not blank
if [ -z "$DB_NAME" ]; then
	echo "DB_NAME was empty! Please specify a database name and/or single-quote database name...";
	exit 1;
fi;
if [ -z "$DB_USER" ]; then
	echo "DB_USER was empty! Please specify user and/or single-quote user...";
	exit 1;
fi;
if [ -z "$DB_PASSWD" ]; then
	echo "DB_PASSWD was empty! Please specify a password and/or single-quote password...";
	exit 1;
fi;

if [ `echo "$DOMAIN $DB_NAME $DB_USER $DB_PASSWD" | grep "[',]"` ]; then
	echo "Invalid characters detected in domain name, database name, database user name, or password!";
	exit 1;
fi;

function display_info {
	# Show some info and prompt user to continue
	echo;
	echo "##################################################################";
	echo "Verify site information before proceeding:";
	#echo "  Project ID: $PROJID";
	echo "  Site Path:		$SITE_PATH";
	echo "  Domain name:		$DOMAIN";
	echo "  DB Host:		$DB_HOST";
	echo "  DB Name:		$DB_NAME";
	echo "  DB User:		$DB_USER";
	echo "  DB Pass:		$DB_PASSWD";
	echo "  SSL:			$SSL";
	#echo "  Conf file: $CONF_FILE";
	#echo "  vHost Symlink: $VHOST_SYMLINK";
	echo "  HTTP IP/Ports:	$HTTP_IPPORTS";
	if [ "$SSL" == "y" ]; then
		echo "  HTTPS IP/Ports:	$HTTPS_IPPORTS";
	fi;
	echo "  DB ACLs:		$ALL_INTERNAL_IPS";
	echo;
	echo "Press enter to continue or CTRL + C to cancel.";
	read -p "##################################################################";
}

function check_db_creds {
	echo "Checking DB credentials for DB Name: $DB_NAME - User: $DB_USER";
	local DB_NAME_LEN=${#DB_NAME};
	local DB_USER_LEN=${#DB_USER};
	local DB_PASS_LEN=${#DB_PASSWD};
	if [ "$DB_NAME_LEN" -lt 3 ]; then
		echo "  DB Name is too small! Length: $DB_NAME_LEN - Min: 3 - Exiting...";
		exit 1;
	fi;
	if [ "$DB_NAME_LEN" -gt 64 ]; then
		echo "  DB Name is too large! Length: $DB_NAME_LEN - Max: 64 - Exiting...";
		exit 1;
	fi;
	
	if [ "$DB_USER_LEN" -lt 3 ]; then
		echo "  DB Username is too small! Length: $DB_USER_LEN - Min: 3 - Exiting...";
		exit 1;
	fi;
	if [ "$DB_USER_LEN" -gt 16 ]; then
		echo "  DB Username is too large! Length: $DB_USER_LEN - Max: 16 - Exiting...";
		exit 1;
	fi;
	
	if [ "$DB_PASS_LEN" -lt 3 ]; then
		echo "  DB password is too small! Length: $DB_PASS_LEN - Min: 3 - Exiting...";
		exit 1;
	fi;
	# TODO: Max password length
}

function db_exists_check {
	echo "Checking to see if DB: $DB_NAME exists...";
	local RES=`$MYSQLSHOW_CMD $DB_NAME | grep -v "Wildcard" | grep -o "$DB_NAME" 2>&1`;
	if [ "$RES" == "$DB_NAME" ]; then
		echo "  Database: $DB_NAME already exists! Exiting...";
		# TODO: Prompt user to continue?
		exit 1;
	fi;
	
	echo "  DB: $DB_NAME does not exist!";
}

function setup_db {
	echo "Creating DB...";
	
	mysql -e"CREATE DATABASE $DB_NAME;";
	if [ "$?" -ne 0 ]; then
		echo "  Error creating DB!";
		exit 1;
	fi;
	
	for i in $ALL_INTERNAL_IPS; do
		echo " Granting user: '$DB_USER' access from: '$i'";
		mysql -e"GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$i' IDENTIFIED BY '$DB_PASSWD';";
		if [ "$?" -ne 0 ]; then
			echo "  Error creating database user!";
			exit 1;
		fi;
	done;
	
	echo "   Done setting up database...";
}

function vhost_exists_check {
	echo "Checking to see if vHost already exists in: $SITE_PATH";
	if [ -e $SITE_PATH ]; then 
		echo "$SITE_PATH already exists! Exiting...";
		# TODO: question user if they want to continue if it already exists?
		exit 1;
	fi;
	echo "Checking to see if sym-link already exists in: $VHOST_SYMLINK";
	if [ -e $VHOST_SYMLINK ]; then 
		echo "$VHOST_SYMLINK already exists! Exiting...";
		# TODO: question user if they want to continue if it already exists?
		exit 1;
	fi;
}

function create_vhost {
	echo "Creating vhost: $DOMAIN";
	
	# Pull down dir structure via git
	echo "  Exporting git vhost-template..";
	(cd $GIT_TEMPLATE_PATH && git checkout-index -a -f --prefix=$VHOST_PATH/)
	
	mv -v $TEMPLATE_PATH $SITE_PATH;
	
	sed -i '/^##/d' $CONF_FILE;
	
	# NOTE: Do this before the section containing IP so it doesn't turn SSLIP into SSLx.x.x.x
	if [ "$SSL" == "n" ]; then
		echo "  Removing SSL from vhost template";
		sed -i '/BEGINSSL/,/ENDSSL/d' $CONF_FILE;
		# Remove SSL certs
		rm -fv $SITE_PATH/ssl/*
	else
		echo "  Configuring SSL...";
		listen_ssl_port_all_web_nodes $NEXTSSLPORT $CONF_FILE;
		#SSLIP=`echo $ALL_IPS | sed "s/80/443/"`;
		sed -i 's/SSLIP/'"$HTTPS_IPPORTS"'/' $CONF_FILE;
		sed -i 's/BEGINSSL//' $CONF_FILE;
		sed -i 's/ENDSSL//' $CONF_FILE;
	fi
	
	# Configure the vhost config file specifically for this site
	sed -i 's/SAFEDOMAIN/'"$SAFEDOMAIN"'/g' $CONF_FILE;
	sed -i 's/DOMAIN/'"$DOMAIN"'/g' $CONF_FILE;
	#sed -i 's/PROJID/'"$PROJID"'/g' $CONF_FILE;
	sed -i 's,VHOSTPATH,'"$VHOST_PATH"',g' $CONF_FILE;
	sed -i 's,SITE_PATH,'"$SITE_PATH"',g' $CONF_FILE;
	sed -i 's/IP/'"$HTTP_IPPORTS"'/g' $CONF_FILE;
	sed -i 's/MYSQLHOST/'"$DB_HOST"'/g' $CONF_FILE;
	sed -i 's/MYSQLDB/'"$DB_NAME"'/g' $CONF_FILE;
	sed -i 's/MYSQLUSER/'"$DB_USER"'/g' $CONF_FILE;
	sed -i 's,MYSQLPASS,'"$DB_PASSWD"',g' $CONF_FILE;
	
	# Log file path
	ACCESS_LOG="$LOG_PATH/vhost-$DOMAIN-access.log";
	ERROR_LOG="$LOG_PATH/vhost-$DOMAIN-error.log";
	
	# Create Log files on all web servers
	run_cmd_all_web_nodes "touch $ACCESS_LOG && touch $ERROR_LOG;";
	
	# Make Apache own log files on all web servers
	run_cmd_all_web_nodes "chown apache:apache $ACCESS_LOG && chown apache:apache $ERROR_LOG;";
	
	# Make sure log dir exists on all web servers
	run_cmd_all_web_nodes "mkdir -p $SITE_PATH/logs && mkdir -p $SITE_PATH/logs;";
	
	# Symlink vhost log path to real log path (so they are all in one place) on all web servers
	run_cmd_all_web_nodes "ln -s $ACCESS_LOG $SITE_PATH/logs/access.log && ln -s $ERROR_LOG $SITE_PATH/logs/error.log;";
	
	# Make sure htdocs folder exists
	mkdir -p $SITE_PATH/htdocs/
	# Make developers own webroot
	chgrp -R developers $SITE_PATH/htdocs/
	
	# Create a symlink in the Apache conf.d folder to the new vhost config file
	ln -s $CONF_FILE $VHOST_SYMLINK;
	
	echo "Wrote symlink: $VHOST_SYMLINK to: $CONF_FILE - Contents:";
	cat $CONF_FILE;
	echo;
	
	# Make sure these files are the same
	diff $VHOST_SYMLINK $CONF_FILE &> /dev/null;
	RES="$?";
	if [ "$RES" -ne 0 ]; then
		echo "Vhost config file symlink differs from actual file! Exiting...";
		exit 1;
	fi;
}

function create_remote_vhost_symlink {
	local HOST="$1";
	echo "Creating vhost symlink on host: $HOST";
	ssh -q root@$HOST "if [ ! -f $VHOST_SYMLINK ]; then ln -s $CONF_FILE $VHOST_SYMLINK && echo '  Created' || '  Not created!'; fi";
}

function get_all_web_server_ips {
	#echo "Getting all host IPs...";
	IPSFILE='/tmp/ipsfile';
	rm $IPSFILE &> /dev/null;
	for HOST in `cat /etc/web-server-list`; do
		#echo "  Getting IP for Host $HOST";
		ssh -q root@$HOST "ifconfig eth0 | grep inet | grep -v inet6 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'" | tr -d '\n' >> $IPSFILE;
		echo -n " " >> $IPSFILE
	done;
	# Remove trailing whitespace
	ALL_IPS=`cat $IPSFILE | sed 's/ *$//g'`;
	echo "  Got web server IPs: '$ALL_IPS'";
	rm $IPSFILE;
}

function get_all_internal_web_server_ips {
	#echo "Getting all internal host IPs...";
	IPSFILE='/tmp/ipsfile';
	rm $IPSFILE &> /dev/null;
	for HOST in `cat /etc/web-server-list`; do
		#echo "  Getting IP for Host $HOST";
		ssh -q root@$HOST "ifconfig eth0:0 | grep inet | grep -v inet6 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'" | tr -d '\n' >> $IPSFILE;
		echo -n " " >> $IPSFILE
	done;
	# Remove trailing whitespace
	ALL_INTERNAL_WEB_IPS=`cat $IPSFILE | sed 's/ *$//g'`;
	echo "  Got Internal Web Server IPS: '$ALL_INTERNAL_WEB_IPS'";
	rm $IPSFILE;
}

function get_all_internal_ips {
	#echo "Getting all internal host IPs...";
	IPSFILE='/tmp/ipsfile';
	rm $IPSFILE &> /dev/null;
	for HOST in `cat /etc/server-list`; do
		#echo "  Getting IP for Host $HOST";
		ssh -q root@$HOST "ifconfig eth0:0 | grep inet | grep -v inet6 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'" | tr -d '\n' >> $IPSFILE;
		echo -n " " >> $IPSFILE
	done;
	echo -n "127.0.0.1" >> $IPSFILE;
	# Remove trailing whitespace
	ALL_INTERNAL_IPS=`cat $IPSFILE | sed 's/ *$//g'`;
	echo "  Got Internal IPS: '$ALL_INTERNAL_IPS'";
	rm $IPSFILE;
}

function ssl_prompt {
	if [ `hostname -s` == "stage" ]; then
		echo "Enabling SSL for staging...";
		SSL="y";
	else
		echo;
		echo "Enable SSL for this site?"
		echo;
		select yn in "Yes" "No"; do
			case $yn in
				Yes ) SSL="y"; break;;
				No ) SSL="n"; break;;
			esac
		done
	fi;
}

function add_port_to_ip_list {
	local __resultvar="$1";
	local IPLIST="$2";
	local PORT="$3";
	local __result="";
	
	for i in $IPLIST; do
		__result="$i:$PORT $__result";
	done;
	
	# Remove trailing whitespace
	__result=`echo $__result | sed 's/ *$//'`;
	
	eval $__resultvar="'$__result'";
}

function get_next_ssl_port {
	local __resultvar="$1";
	local __result="";
	__result=`grep 'Listen' $SSL_LISTEN_FILE | sort | tail -n1 | awk '{print $2}' | awk -F':' '{print $2}'`;
	let __result++;
	echo "  Next available SSL port: '$__result'";
	eval $__resultvar="'$__result'";
}

function listen_ssl_port_all_web_nodes {
	local PORT="$1";
	local VHOSTCONFFILE="$2";
	
	if [ ! `echo $PORT | grep -e '^1[0-9]\{4\}$'` ]; then
		echo;
		echo "Attempted to configure Apache to listen on an invalid SSL port! ($PORT)";
		echo "Exiting....";
		echo;
		exit 1;
	fi;
	
	for i in `cat /etc/web-server-list`; do
		ssh -q root@$i "echo -e \"# $VHOSTCONFFILE\\nListen \`ifconfig eth0:0 | grep inet | awk -F' ' '{print \$2}' | awk -F':' '{print \$2}'\`:$PORT https\" >> $SSL_LISTEN_FILE";
		RES="$?";
		if [ "$RES" -ne 0 ]; then
			echo;
			echo "Error writing SSL Listen directive to Host: '$i' - File: '$SSL_LISTEN_FILE'";
			echo "Exiting....";
			echo;
			exit 1;
		fi;
	done;
	
	echo "  Reserved SSL port: $PORT for '$VHOSTCONFFILE'";
}

function add_to_staging {
	ADD_TO_STAGING="n";
	if [ `hostname -s` == "stage" ]; then
		# Nothing to do since we are on staging
		echo;
	else
		echo;
		echo "Add site to staging?"
		echo;
		select yn in "Yes" "No"; do
			case $yn in
				Yes ) ADD_TO_STAGING="y"; break;;
				No ) ADD_TO_STAGING="n"; break;;
			esac
		done
	fi;
	
	if [ "$ADD_TO_STAGING" == "y" ]; then
		echo;
		echo "Adding to staging...";
		echo;
		
		# This means cannot use ' char...
		# TODO: Check input for ' char
		ssh -t root@stage-int "site-add.sh '$DOMAIN' '$DB_NAME' '$DB_USER' '$DB_PASSWD'";
		RES=$?;
		#echo "RESULT FROM ADD TO STAGING: '$RES'";
		if [ "$RES" != "0" ]; then
			echo;
			echo "Failed adding to staging! Exiting...";
			echo;
			exit 1;
		else
			echo;
			echo "Done adding in staging...";
			echo "Adding to production next";
			echo;
		fi;
	fi;
}

##########################################
# BEGIN - Script logic
##########################################

echo 'Done';
exit 1;

get_all_web_server_ips;
get_all_internal_ips;
get_all_internal_web_server_ips;

# Perform some checks
check_db_creds;
check_apache_all_nodes;
apache_running_all_hosts;
db_exists_check;
vhost_exists_check;

add_to_staging;

# Ask user if site will be SSL or not
ssl_prompt;

add_port_to_ip_list INT_HTTP_WEB_IPPORTS "$ALL_INTERNAL_WEB_IPS" 80
add_port_to_ip_list PUB_HTTP_WEB_IPPORTS "$ALL_IPS" 80
# List of HTTP IP:PORT
HTTP_IPPORTS="$INT_HTTP_WEB_IPPORTS $PUB_HTTP_WEB_IPPORTS";

if [ "$SSL" == "y" ]; then
	# Get the next available SSL port for load balanced IPs
	get_next_ssl_port NEXTSSLPORT
	add_port_to_ip_list INT_HTTPS_WEB_IPPORTS "$ALL_INTERNAL_WEB_IPS" $NEXTSSLPORT
	add_port_to_ip_list PUB_HTTPS_WEB_IPPORTS "$ALL_IPS" 443
	# List of HTTPS/SSL IP:PORT
	HTTPS_IPPORTS="$PUB_HTTPS_WEB_IPPORTS $INT_HTTPS_WEB_IPPORTS";
fi

# Display settings to user before creating anything
display_info;

setup_db;
create_vhost;

force_csync2;

# TODO: autodetect which host this is in case web1 is administratively down
for i in `cat /etc/web-server-list`; do
	check_apache $i;
	#force_rsync $i;
	create_remote_vhost_symlink $i;
	# Check apache again to make sure there are no issues with the config file
	check_apache $i;
	restart_apache $i;
	apache_health_check $i;
	
	echo "Web content updated and Apache restarted on Host: $HOST";
done;

flush_privileges;

echo;
echo "##############################################";
echo "                    DONE";
echo "##############################################";
echo;

##########################################
# END - Script logic
##########################################
