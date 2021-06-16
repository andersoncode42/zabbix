#!/bin/bash


#**************************************
# DESCRIPTION
#    
# AUTHOR
#    Anderson
# SOURCE
#                               
#**************************************


# Configurations
readonly ZBX_AG_PKG="zabbix40-agent" # Required
readonly ZBX_AG_PORT="10050"

readonly ZBX_SRV_IP="10.0.255.2" #Required

readonly CFG_FILE="/etc/zabbix_agentd.conf"
readonly CFG_REGEX_SERVER="s/Server=127.0.0.1/Server=127.0.0.1,${ZBX_SRV_IP}/g"
readonly CFG_REGEX_SERVERACTIVE="s/ServerActive=127.0.0.1/ServerActive=127.0.0.1,${ZBX_SRV_IP}/g"

readonly SERVICE_NAME="zabbix-agent"

readonly FIREWALL_FILE="/usr/lib/firewalld/services/zabbix-agent.xml"
read -r -d '' FIREWALL_FILE_CONTENT << EOM
<?xml version="1.0" encoding="utf-8"?>
    <service>
        <short>${SERVICE_NAME}</short>
        <description>Zabbix Agent</description>
        <port protocol="tcp" port="${ZBX_AG_PORT}"/>
</service>
EOM

readonly TEST_COMMAND="zabbix_get -s 127.0.0.1 -k net.tcp.port[${ZBX_SRV_IP},10051]"


step(){
    printf "\n\n"
    sleep 2
    echo "-------------------------"
    echo "| Step: ${1}"
    echo "--------------------------"
}


step "INSTALATION"
echo "---> Remove any packages that already exist"
yum -y remove "zabbix*"
echo "---> Installing Zabbix Agent"
yum -y install "${ZBX_AG_PKG}"
#
#
step "CONFIGURATION FILE"
echo "---> Editing config file"
sed -i "${CFG_REGEX_SERVER}"       "${CFG_FILE}"
sed -i "${CFG_REGEX_SERVERACTIVE}" "${CFG_FILE}"
echo "File was configured successfully"
#
#
step "SERVICE"
systemctl enable zabbix-agent
systemctl start zabbix-agent
echo "Service is ok"
#
#
step "FIREWALL"
echo "---> Creating firewall file"
echo "${FIREWALL_FILE_CONTENT}" > "${FIREWALL_FILE}"
echo "---> Changing file permissions"
chmod -v 640 "${FIREWALL_FILE}"
restorecon -v "${FIREWALL_FILE}"
echo "---> Configuring firewalld"
firewall-cmd --permanent --add-service="${SERVICE_NAME}"
firewall-cmd --reload
#
#
step "TEST"
result="$(${TEST_COMMAND})"
echo "The test result was: ${result}"
if [ "${result}" = "1" ]
    then
        echo "OK - Success"
    else
        echo "ERROR - The test failed"
        exit 1
fi
#
step "THE END"