#!/bin/bash
ssh -o StrictHostKeyChecking=no -i ~/.ssh/devops-capstone.pem ubuntu@18.215.124.123 << 'ENDSSH'
echo "=== Services ==="
for svc in jenkins nginx docker; do
  status=$(systemctl is-active $svc 2>/dev/null)
  echo "  $svc: $status"
done

echo ""
echo "=== Docker containers ==="
docker ps --format "  {{.Names}}: {{.Status}}" 2>/dev/null

echo ""
echo "=== Listening ports ==="
ss -tlnp | grep -E "8080|9090|3000|9093|9115" | awk '{print "  "$4}'

echo ""
echo "=== Jenkins initial password ==="
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "  (JCasC configured — no initial password needed)"
ENDSSH
