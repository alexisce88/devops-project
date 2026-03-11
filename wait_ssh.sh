#!/bin/bash
IPS="18.215.124.123 3.223.127.51 3.238.148.134 32.192.24.69"
NAMES="jenkins staging blue green"
echo "Waiting for all instances to accept SSH connections..."
idx=0
for ip in $IPS; do
  idx=$((idx+1))
  name=$(echo $NAMES | awk "{print \$$idx}")
  printf "  %-12s (%s): " "$name" "$ip"
  for attempt in $(seq 1 30); do
    result=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/devops-capstone.pem ubuntu@$ip 'echo ok' 2>/dev/null)
    if [ "$result" = "ok" ]; then
      echo "READY"
      break
    fi
    printf "."
    sleep 5
  done
done
echo ""
echo "All servers reachable!"
