#update linux repos
set -o xtrace # or use bash -x <shell-file>
#sudo yum update -y


## FOR EC2 additionally need to setup security groups
# ON -  port 9100 (node_exporter), 9090 (prometheus), 3000 (grafana) (whatever is running on the machine)


################################# PROMETHEUS SERVER SETUP ####################################
PROMETHEUS_HOST=localhost
PROMETHEUS_PORT=9090

# -----------create prometheus user and directories -------------
echo "create prometheus user and directories"
sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# ---------------- download, copy files and install prometheus --------------
echo "downloading and installing prometheus"
wget  https://github.com/prometheus/prometheus/releases/download/v2.37.1/prometheus-2.37.1.linux-amd64.tar.gz
tar -xvf prometheus-2.37.1.linux-amd64.tar.gz
sudo cp prometheus-2.37.1.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.37.1.linux-amd64/promtool /usr/local/bin
sudo cp -r prometheus-2.37.1.linux-amd64/consoles /etc/prometheus/
sudo cp -r prometheus-2.37.1.linux-amd64/console_libraries /etc/prometheus

## ------------basic settings file for prometheus self monitoring --------------
echo "basic settings file for prometheus self monitoring"
touch prometheus.yml

read -r -d '' PROMETHEUS_BASIC_CONFIG << EOM
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: [$PROMETHEUS_HOST:$PROMETHEUS_METRICS_PORT]
EOM

sudo echo "$PROMETHEUS_BASIC_CONFIG" >> prometheus.yml
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
rm prometheus.yml

#--------------- changing ownership for files created by prometheus -----------------
echo "changing ownership for files and folders for prometheus"
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

# --------------- create a service file for prometheus -----------------------
echo "creating a service file for prometheus"
touch prometheus.service
read -r -d '' PROMETHEUS_SERVICE_CONFIG << EOM
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOM
sudo echo "$PROMETHEUS_SERVICE_CONFIG" >> prometheus.service
sudo cp prometheus.service /etc/systemd/system/prometheus.service
rm prometheus.service
echo "service file created for prometheus"

# -------------- starting the prometheus daemon -------------------
echo "starting the prometheus daemon"
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus


# ----------------- removing temp files and folders ----------------
echo "copying done. removing promethues downloaded files"
rm -rf prometheus-2.37.1.linux-amd64.tar.gz prometheus-2.37.1.linux-amd64

#check prometheus metrics emitted on http://<EC2-MACHINE-IP>:9090/metrics

