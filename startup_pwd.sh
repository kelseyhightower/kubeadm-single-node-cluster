#! /bin/bash


set -e

if [ -n "$DEBUG" ]; then
    set -x
fi

function jsonval() {
    temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
    echo ${temp##*|}
}

if [[ -z "$PWK_URL" && -z "$1" ]]; then
    echo "URL or PWK_URL env must be specified"
    exit 1
fi

URL=${PWK_URL:-$1}
ENDPOINT=$(echo $URL |  awk -F/ '{print "http://"$3"/sessions/"$NF"/instances"}')
HOSTNAME=$(echo $URL |  awk -F/ '{print $3}')
echo "Creating PWK Instance..."
CREATE_JSON=$(curl -sS -XPOST $ENDPOINT)
INSTANCE_IP=$(jsonval $CREATE_JSON ip)
INSTANCE_DASH_IP=${INSTANCE_IP//./-}
INSTANCE_NAME=$(jsonval $CREATE_JSON name)
SESSION_PREFIX=${INSTANCE_NAME%%_*}


INIT=$(cat << EOF
kubeadm init --apiserver-advertise-address $INSTANCE_IP 
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml 
EOF
)


echo "
Configuring session...
"
for i in {1..5}; do
    if ssh -o ConnectTimeout=2 -p 1022 -t $INSTANCE_DASH_IP-$SESSION_PREFIX@$HOSTNAME "$INIT"; then
        echo "
        Setup kubectl locally
        "
        kubectl config set-credentials pwk_admin --token="system:admin/system:masters"
        kubectl config set-cluster pwk --user=pwk_admin --insecure-skip-tls-verify=true --server=https://ip${INSTANCE_DASH_IP}-6443.${HOSTNAME}
        kubectl config set-context pwk --cluster=pwk --user=pwk_admin
        kubectl config use-context pwk
        exit 0
    fi
done

exit 1

