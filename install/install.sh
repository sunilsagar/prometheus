#!/bin/bash
# Purpose : Installation of Prometheus(latest)
# This performs all required steps on server .
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /opt/prometheus
sudo mkdir /opt/prometheus/data
sudo chown prometheus:prometheus /opt/prometheus/data /opt/prometheus

echo "Prometheus Download is in progress .."
cd /tmp
url="$(curl -s https://prometheus.io/download/  | grep 'prometheus-.*amd64.tar.gz' | grep -v 'rc' | grep linux | awk '{print $NF}' | cut -d '"' -f2)"
sleep 2
curl -sLo /tmp/prometheus.tar.gz ${url}

echo "Prometheus Installation in progress .."
sleep 2
tar -xzf /tmp/prometheus.tar.gz

mv prometheus*linux-amd64 prometheus
sudo cp /tmp/prometheus/prometheus /usr/local/bin/
sudo cp /tmp/prometheus/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

sudo cp -r prometheus/consoles /opt/prometheus
sudo cp -r prometheus/console_libraries /opt/prometheus
sudo chown -R prometheus:prometheus /opt/prometheus/consoles /opt/prometheus/console_libraries


echo "Initial prometheus.yml file created at path /opt/prometheus"
sudo cat << EOF > /opt/prometheus/prometheus.yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
EOF
	  
chown prometheus:prometheus /opt/prometheus/prometheus.yml

echo "Prometheus Service create progress .. "
sudo cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /opt/prometheus/prometheus.yml \
    --storage.tsdb.path /opt/prometheus/data/ \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling prometheus service to start at server reboot .."

sudo systemctl daemon-reload
sudo systemctl enable prometheus > /dev/null 2>&1
echo "Prometheus start in progress .."
sudo systemctl start prometheus
sleep 2
echo "Prometheus Status .."
sudo systemctl status prometheus

# Cleanup 
rm -rf /tmp/prometheus /tmp/prometheus.tar.gz
