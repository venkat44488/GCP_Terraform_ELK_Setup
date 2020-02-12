#!/bin/bash
yum update -y
yum -y install java-openjdk-devel java-openjdk

cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum clean all
echo "running yum makecache............"
yum makecache > /tmp/cache.log
echo "INSTALLING ELASTISERARCH........"
yum -y install elasticsearch > /tmp/elastiserarch.log

sed -ie 's/-Xms1g/-Xms256m/g' /etc/elasticsearch/jvm.options
sed -ie 's/-Xmx1g/-Xms512m/g' /etc/elasticsearch/jvm.options

systemctl enable --now elasticsearch.service
echo "Elastisearch enabled........"
curl http://127.0.0.1:9200  > curl.status
curl -X PUT "http://127.0.0.1:9200/mytest_index" >>curl.status

yum -y install kibana > /tmp/kibaba.log


sed -ie 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml
#sed -ie 's/#server.name: "your-hostname"/server.name: '"$hostname"'/g' /etc/kibana/kibana.yml
sed -ie 's/#server.name: "your-hostname"/server.name: '`hostname`'/g' /etc/kibana/kibana.yml
sed -i '28s/#/ /1g' kibana.yml
systemctl enable --now kibana
echo " INSTALLING LOGSTASH........."
yum -y install logstash
