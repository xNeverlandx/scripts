Manual

prometheus.sh => install prometheus.
localhost:9090

grafana.sh => install grafana.
localhost:3000
You need to configure manually Data source(Prometheus).

install-aws-tools.sh => install aws tool and kops for kubernetes cluster.

kubernetes-claster.sh => setup k8s cluster.
You need to setup in file (PREFIX, URL, AWS_REGION).


Queue

1. install-aws-tools.sh
2. kubernetes-claster.sh
3. prometheus.sh
4. grafana.sh