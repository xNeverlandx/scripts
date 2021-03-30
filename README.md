Manual

prometheus.sh => install prometheus.
localhost:9090

grafana.sh => install grafana.
localhost:3000
You need to configure manually Data source(Prometheus).

install-aws-tools.sh => install aws tool and kops for kubernetes cluster.

kubernetes-claster.sh => setup k8s cluster.
You need to write in file your (PREFIX, URL, AWS_REGION).


Queue
1. Create aws server with ubuntu
2. install-aws-tools.sh
3. kubernetes-claster.sh (Unfortunately I could not test this script because I do not have an aws account, but based on the guides I read, it should work)
4. prometheus.sh
5. grafana.sh
