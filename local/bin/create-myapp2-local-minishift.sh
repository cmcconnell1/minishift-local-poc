#!/usr/bin/env bash
#set -v
#
# ===========================================
#         MONOLITHIC KUBE TOPOLOGY
# ===========================================
# NS / PROJECT   APP_NAME   DOCKER-IMAGE
# ===========================================
# myapp2-local   myapp2      myapp2-client
# myapp2-local   myapp2      myapp2-server
# etc...
# ===========================================
# myapp2-dev     myapp2      myapp2-client
# myapp2-dev     myapp2      myapp2-server
# etc...
# ===========================================
# myapp2-stage   myapp2      myapp2-client
# myapp2-stage   myapp2      myapp2-server
# etc...
# ===========================================
# myapp2-prod    myapp2      myapp2-client
# myapp2-prod    myapp2      myapp2-server
# etc...
# ===========================================

ENV="local"

BASEDIR=${GIT_HOME}/my-repo-pass
cd "${BASEDIR}" >/dev/null 2>&1 || git clone https://github.com/mycompany/my-repo-paas.git && cd "${BASEDIR}"

export myapp2_client_ver=0.7.854 # or provide requisite initial docker image / version

eval $(minishift docker-env)

oc project myapp2-local || oc new-project myapp2-local

docker login -u developer -p `oc whoami -t` 172.30.1.1:5000

# login to AWS ECR you might not need this but your source goes here--i.e. where are your docker images coming from. . .
COMMAND=$(aws ecr get-login --region us-west-1 --no-include-email) ; echo $(eval $COMMAND) # aws ecr login
docker pull 0123456789012.dkr.ecr.us-west-1.amazonaws.com/myapp2/myapp2-client:${myapp2_client_ver}

docker tag 0123456789012.dkr.ecr.us-west-1.amazonaws.com/myapp2/myapp2-client:${myapp2_client_ver} myapp2-local/myapp2-client:${myapp2_client_ver}

docker tag myapp2-local/myapp2-client:${myapp2_client_ver} myapp2-local/myapp2-client:latest
#docker tag myapp2-local/myapp2-client:${myapp2_client_ver} 172.30.1.1:5000/myapp2-local/myapp2-client:${myapp2_client_ver}

docker tag myapp2-local/myapp2-client 172.30.1.1:5000/myapp2-local/myapp2-client

# create the myapp2-client image stream in the myapp2-local project/ns
oc create is myapp2-client -n myapp2-local

#docker push 172.30.1.1:5000/myapp2-local/myapp2-client:${myapp2_client_ver}
docker push 172.30.1.1:5000/myapp2-local/myapp2-client

# create the myapp2-client-secret else get permission denied
oc create secret docker-registry myapp2-secret --docker-server=https://172.30.1.1:5000 --docker-username=developer --docker-password=developer123 --docker-email=hamster123@yourisp.com

# link the secret
oc secrets link default myapp2-secret

oc new-app --name=myapp2 --image-stream=myapp2-client --env-file=${BASEDIR}/${ENV}/conf/myapp2/myapp2-config -l name=myapp2 -l promotion-group=myapp2 # promotion-group for promoting any/all in NS/project if needed
# without the latest useless and confusing tag we must specify the image stream explicitly
#oc new-app --name=myapp2 --env-file=${BASEDIR}/${ENV}/conf/myapp2/myapp2-config -l name=myapp2 -l promotion-group=myapp2 --image-stream="myapp2-local/myapp2-client:${myapp2_client_ver}"

# minishift/openshift is cool in that it has routes which are way ahead of vanilla kube IMHO having to deal with ingress in the wild wild west, etc.
oc expose svc/myapp2
