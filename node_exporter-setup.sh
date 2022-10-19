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
touch node-exporter.service
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
sudo echo "$NODE_EXPORTER_SERVICE_CONFIG" >> node-exporter.service
sudo cp node-exporter.service /etc/systemd/system/node-exporter.service
rm node-exporter.service
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

