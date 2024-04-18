 #!/bin/bash
 #!/bin/bash
[ $UID -eq 0 ] || 
{ echo "This script needs to be run with sudo or by root."; exit 1; }

# Включение строгой проверки на наличие ошибок
set -o errexit
set -o nounset
set -o pipefail

# Проверка наличия необходимых утилит
check_dependencies() {
    local dependencies='systemctl firewalld osqueryi jq awk tr wc'
    for dep in $dependencies; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Error: $dep is not installed or not in PATH"
            exit 1
        fi
    done
}

start_firewalld() {
	systemctl start firewalld
	systemctl enable firewalld
}

status_firewalld() {
	echo -en "\nFIREWALLD VERSION: "
	rpm -q firewalld
	echo -en "\nSTATUS: "
	firewall-cmd --state
	echo -e "\nLIST: "
	firewall-cmd --list-all
}

clear_rule() {
	echo -en "\nCLEAR: "
	firewall-cmd --complete-reload
}

data_collection() {
	local ip_data_raw
	ip_data_raw=$(echo 'SELECT (
			  CASE family 
			  WHEN 2 THEN "IP4" 
			  ELSE family END
			) AS family, (
			  CASE protocol 
			  WHEN 6 THEN "TCP" 
			  WHEN 17 THEN "UDP" 
			  ELSE protocol END
			) AS protocol, local_address, local_port, 
			  remote_address
			FROM process_open_sockets 
			WHERE family IN (2) 
			AND protocol IN (6, 17) 
			LIMIT 4;' | osqueryi --json)
			
	local ip_data
	ip_data=$(echo "$ip_data_raw" | jq -r '.[]')
	
	echo "$ip_data"
}

main() {
	check_dependencies
	status_clear_rule
}

main
