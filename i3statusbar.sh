#!/bin/bash

# Author: pythops
# License: GPLv3


## Colors
OK="#4fe305"
ALERT="#e32c05"
WARNING="#ecab20"

## Network ##
network() {
  IP=$(ip route show default | awk '{print $9}')
  if [ "$IP" ]; then
    ESSID=$(iwgetid | awk '{gsub(/:/, " ");gsub(/"/, "");gsub(" ", "", $3); print $3}')
    if [ "$ESSID" ]; then
      echo "{\"name\": \"Network\", \"full_text\": \" $ESSID $IP\", \"color\": \"$OK\"},"
    else
      echo "{\"name\": \"Network\", \"full_text\": \" $IP\", \"color\": \"$OK\"},"
    fi
  else
    echo "{\"name\": \"Network\", \"full_text\": \"Network Down\", \"color\": \"$ALERT\"},"
  fi
}

# TODO
bandwidth() {
  INTERFACE=$(ip route show default | awk '{print $5}')
  if [ "$INTERFACE" ]; then
    echo "{\"name\": \"Bandwidth\", \"full_text\": \"IN 0  OUT 0\"},"
  fi
}

## Disk ##
disk() {
  #### Home
  HOME=$(df -h 2>/dev/null | rg /home$ | awk '{gsub("%","", $5);print $5}')
  if [ "$(echo "$HOME < 80" | bc)" -eq 1 ]; then
    echo "{\"name\": \"DISK_HOME\", \"full_text\": \" Home $HOME%\"},"
  elif [ "$(echo "$HOME >= 80 && $HOME < 90" | bc)" -eq 1 ]; then
    echo "{\"name\": \"DISK_HOME\", \"full_text\": \" Home $HOME%\", \"color\": \"$WARNING\"},"
  else
    echo "{\"name\": \"DISK_HOME\", \"full_text\": \" Home $HOME%\",\"color\": \"$ALERT\"},"
  fi

  #### Root
  ROOT=$(df -h 2>/dev/null | rg /$ | awk '{gsub("%","", $5);print $5}')
  if [ "$(echo "$ROOT < 80" | bc)" -eq 1 ]; then
    echo "{\"name\": \"DISK_ROOT\", \"full_text\": \" Root $ROOT%\"},"
  elif [ "$(echo "$ROOT >= 80 && $ROOT < 90" | bc)" -eq 1 ]; then
    echo "{\"name\": \"DISK_ROOT\", \"full_text\": \" Root $ROOT%\",\"color\": \"$WARNING\"},"
  else
    echo "{\"name\": \"DISK_ROOT\", \"full_text\": \" Root $ROOT%\",\"color\": \"$ALERT\"},"
  fi
}

## CPU ##
cpu_stats() {
  CPU_UTIL=$(mpstat  | awk 'NR==4 {print $4}')
  CPU_IOWAIT=$(mpstat  | awk 'NR==4 {print $7}')
  CPU_LOAD=$(w | awk -F ':' 'NR==1 {gsub(",","",$NF); print $NF}')
  echo "{\"name\": \"CPU_UTIL\", \"full_text\": \" $CPU_UTIL%\"},"
  echo "{\"name\": \"CPU_IOWAIT\", \"full_text\": \"IOWait $CPU_IOWAIT\"},"

  if [ "$(echo "$(echo "$CPU_LOAD" | awk '{print $1}') > $(grep -c ^processor /proc/cpuinfo)" | bc)" -eq 0 ]; then
    echo "{\"name\": \"LOAD_AVR\", \"full_text\": \"Load Avg $CPU_LOAD\",\"color\": \"$OK\"},"
  else
    echo "{\"name\": \"LOAD_AVR\", \"full_text\": \"Load Avg $CPU_LOAD\", \"color\": \"$ALERT\"},"
  fi
}

## MEMORY ##
memory() {
  MEMORY_TOTAL=$(free -m | awk '/Mem/ {print $2}')
  MEMORY_USED=$(free -m | awk '/Mem/ {print $3}')
  if [ "$(echo "scale=2;$MEMORY_USED / $MEMORY_TOTAL < .75" | bc)" -eq 1 ]; then
    echo "{\"name\": \"Memory\", \"full_text\": \"Mem $MEMORY_USED/$MEMORY_TOTAL (MB)\", \"color\": \"$OK\"},"

  elif [ "$(echo "scale=2;$MEMORY_USED / $MEMORY_TOTAL > .75 && $MEMORY_USED / $MEMORY_TOTAL < .9" | bc)" -eq 1 ]; then
    echo "{\"name\": \"Memory\", \"full_text\": \"Mem $MEMORY_USED/$MEMORY_TOTAL (MB)\", \"color\": \"$WARNING\"},"

  else
    echo "{\"name\": \"Memory\", \"full_text\": \"Mem $MEMORY_USED/$MEMORY_TOTAL (MB)\", \"color\": \"$ALERT\"},"
  fi
}

## Battery ##
battery() {
  BATTERY_STATUS=$(acpi --battery | awk -F ',' '{gsub(/:/, ",");gsub(" ", "", $2); print$2}')
  BATTERY_PERC=$(acpi --battery | awk -F ',' '{gsub(/:/, ",");gsub(" ", "", $3);gsub("%", "", $3); print$3}')

  if [ "$(echo "$BATTERY_PERC > 90" | bc)" -eq 1 ]; then
    echo "{\"name\": \"BATTERY_PERC\", \"full_text\": \" $BATTERY_PERC%\", \"separator\": false},"
    echo "{\"name\": \"BATTERY_STATUS\", \"full_text\": \"$BATTERY_STATUS\"},"
  elif [ "$(echo "$BATTERY_PERC <= 90 && $BATTERY_PERC >= 75" | bc)" -eq 1 ]; then
    echo "{\"name\": \"BATTERY_PERC\", \"full_text\": \" $BATTERY_PERC%\", \"separator\": false},"
    echo "{\"name\": \"BATTERY_STATUS\", \"full_text\": \"$BATTERY_STATUS\"},"
  elif [ "$(echo "$BATTERY_PERC < 75 && $BATTERY_PERC >= 30" | bc)" -eq 1 ]; then
    echo "{\"name\": \"BATTERY_PERC\", \"full_text\": \" $BATTERY_PERC%\", \"separator\": false},"
    echo "{\"name\": \"BATTERY_STATUS\", \"full_text\": \"$BATTERY_STATUS\"},"
  elif [ "$(echo "$BATTERY_PERC < 30 && $BATTERY_PERC >= 20" | bc)" -eq 1 ]; then
    echo "{\"name\": \"BATTERY_PERC\", \"full_text\": \" $BATTERY_PERC%\", \"color\": \"$WARNING\", \"separator\": false},"
    echo "{\"name\": \"BATTERY_STATUS\", \"full_text\": \"$BATTERY_STATUS\", \"color\": \"$WARNING\"},"
  else
    echo "{\"name\": \"BATTERY_PERC\", \"full_text\": \" $BATTERY_PERC%\", \"color\": \"$ALERT\" ,\"separator\": false},"
    echo "{\"name\": \"BATTERY_STATUS\", \"full_text\": \"$BATTERY_STATUS\", \"color\": \"$ALERT\"},"
  fi
}

## Docker
docker_containers (){
  DOCKER_RUNNING_CONTAINERS=$(docker ps -q | wc -l )
  echo "{\"name\": \"DOCKER\", \"full_text\": \" $DOCKER_RUNNING_CONTAINERS\", \"color\": \"#099CEC\"},"
}

## VMs
vm () {
  RUNNING_VMS=$(vboxmanage list runningvms | wc -l)
  echo "{\"name\": \"VMs\", \"full_text\": \" $RUNNING_VMS\"},"
}

## Volume
volume() {
  IS_ON=$(amixer -D pulse get Master | rg "Front Left:" | awk '{print $6}' | tr -d "[]")
  if [ "$IS_ON" == "on" ]; then
    VOLUME=$(amixer -D pulse get Master | grep "Front Left:" | awk '{print $5}' | tr -d "[]")
    echo "{\"name\": \"Volume\", \"full_text\": \" $VOLUME\"},"
  else
    echo "{\"name\": \"Volume\", \"full_text\": \" Off\"},"
  fi
}

## Date (The last in the list)
date_time (){
  echo "{\"name\": \"DATE\", \"full_text\": \" $(date '+%Y-%m-%d %H:%M:%S')\", \"color\":\"#4fe305\"}"
}

# Rendering
echo '{ "version": 1 }'

echo '['

while :;
do
	echo "[
	$(network)
	$(bandwidth)
	$(disk)
	$(cpu_stats)
	$(vm)
	$(docker_containers)
	$(memory)
	$(volume)
	$(battery)
	$(date_time)
	],"
	sleep 1
done
