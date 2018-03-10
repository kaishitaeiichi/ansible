#!/bin/bash

set -e -u

config_path='/etc/metricbeat/metricbeat.yml'
host_name=''
elasticsearch_host=''
args_index="0"
args=()

while [ $# -gt 0 ]; do
    case "$1" in
        "--config_path") config_path=$2; shift 2;; 
        "--host_name") host_name=$2; shift 2;; 
        "--elasticsearch_host") elasticsearch_host=$2; shift 2;; 
        *) args[$args_index]=$1; args_index=$(($args_index + 1)); shift 1;; 
    esac 
done

sed -i -r 's/#name:/name: '${host_name}'/g' $config_path
sed -i -r 's/localhost:9200/'${elasticsearch_host}':9200/g' $config_path

function add_config {
    local config_path="$1"
    local config_name="$2"
    local config_content="$3"

    local START_NUM=$(grep -n "#### $config_name START ####" $config_path | cut -d':' -f1)
    local END_NUM=$(  grep -n "#### $config_name END ####"   $config_path | cut -d':' -f1)

    if [ "$START_NUM" ] && [ "$END_NUM" ]; then
        sed -i "${START_NUM},${END_NUM}d" $config_path
    fi
    cat <<CONFIG >> $config_path
#### $config_name START ####
$config_content
#### $config_name END ####
CONFIG

}

config_content=$(cat <<CONFIG 
metricbeat.modules:
- module: system
  metricsets:
  - core
  - cpu
  - diskio
  - filesystem
  - fsstat
  - load
  - memory
  - network
  - process
  - process_summary
#  - raid
#  - socket
  - uptime
  enabled: true
  period: 60s
  processes: ['.*']
  cpu_ticks: false
CONFIG
)

add_config "$config_path" 'metricbeat.modules' "$config_content"


