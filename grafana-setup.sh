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

