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

###############################################################################################

##################################### NODE_EXPORTER SETUP #####################################
NODE_METRICS_PORT=9100

# ---------------- download and install node_exporter --------------
echo "downloading and installing node exporter"
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
sudo useradd --no-create-home node_exporter
tar xvf node_exporter-1.4.0.linux-amd64.tar.gz
sudo cp node_exporter-1.4.0.linux-amd64/node_exporter /usr/local/bin/node_exporter

#--------------- changing ownership for files created by prometheus -----------------
echo "changing ownership for files and folders for node exporter"
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# --------------- create a service file for prometheus -----------------------
echo "creating service file for node_exporter"
touch node_exporter.service
read -r -d '' NODE_EXPORTER_SERVICE_CONFIG << EOM
[Unit]
Description=Prometheus Node Exporter Service
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOM
sudo echo "$NODE_EXPORTER_SERVICE_CONFIG" >> node_exporter.service
sudo cp node_exporter.service /etc/systemd/system/node_exporter.service
rm node_exporter.service
echo "service file created for node_exporter"

# -------------- starting the node_exporter daemon -------------------
echo "starting daemon on machine"
sudo systemctl daemon-reload
sudo systemctl enable node-exporter
sudo systemctl start node-exporter
sudo systemctl status node-exporter

#------------ removing temp files and folders -------------------
rm -rf node_exporter-1.4.0.linux-amd64.tar.gz node_exporter-1.4.0.linux-amd64

#check metrics emitted on http://<EC2-MACHINE-IP>:9100/metrics

#Add a job in prometheus.yml for this machine if you want to scrape data from this machine
#- job_name: 'node_exporter'
#  static_configs:
#    - targets: ['<EC2-MACHINE-IP>:9100']


#########################################################################################

##################################### GRAFANA SETUP #####################################
GRAFANA_PORT=3000
#sudo yum update -y

# ---------------------- download and install grafana -----------------------
echo "downloading and installing grafana"
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-9.2.1-1.x86_64.rpm
sudo yum install grafana-enterprise-9.2.1-1.x86_64.rpm

#--------------- starting service daemon--------------------
echo "starting service daemon for grafana"
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server
sudo systemctl enable grafana-server.service

#-------------- deleting temp files and folders -----------------------------
rm grafana-enterprise-9.2.1-1.x86_64.rpm

#check grafana UI on http://<EC2-MACHINE-IP>:3000
#The default username and password is admin.


############################################################################################

###################################### MYSQL SETUP #########################################
#same as node_exporter setup for machine


#############################################################################################

##################################### APPLICATION SETUP #####################################
# same as node_exporter setup for machine
#- job_name: 'django'
#  scrape_interval: 10s
#  static_configs:
#    - targets: ['<EC2-MACHINE-IP>:8000']


