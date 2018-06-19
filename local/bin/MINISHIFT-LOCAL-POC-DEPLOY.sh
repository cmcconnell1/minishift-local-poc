#!/usr/bin/env bash

cd $GIT_HOME/td-openshift-paas/local

minishift config set memory 4G
minishift config set cpus 4
minishift config set vm-driver virtualbox
minishift config set disk-size 30G
#minishift config set insecure-registry 0.0.0.0/0 # this wont work must be explicit
# #minishift start --memory=4G --cpus=4 --vm-driver=virtualbox --insecure-registry 172.30.0.0/16 --insecure-registry minishift --insecure-registry docker-registry-default.127.0.0.1.nip.io  --insecure-registry 0.0.0.0/0

# must be comma delim no spaces and explict for ALL
minishift config set insecure-registry 172.30.0.0/16,172.30.1.1,minishift,docker-registry-default.127.0.0.1.nip.io,docker-registry-default.192.168.99.100.nip.io,0123456789012.dkr.ecr.us-west-1.amazonaws.com/myapp/myapp1,0123456789012.dkr.ecr.us-west-1.amazonaws.com/myapp/myapp2,0123456789012.dkr.ecr.us-west-1.amazonaws.com/myapp/myapp2

minishift addon enable anyuid # should be installed and enabled by default
minishift addon enable admin-user # should be installed and enabled by default
minishift addon enable registry-route # should be installed and enabled by default

#minishift config view
#echo "'cat /Users/cmcc/.minishift/config/config.json to see the 'minishift config options configuration file'"
minishift start

# login to the OpenShift docker registry:
eval $(minishift docker-env)
eval $(minishift oc-env)

# get admin token for the minishift registry
#oc login --username=developer --password=admin123
export token=$(oc whoami -t)
oc login --token=$token

# REQUIRED AS CONTAINERS RUN AS ROOT NOT ALLOWED IN OPENSHIFT
# configure Minishift to allow containers to run as root with this command: note this is per project (use 'oc project myapp-n' first when we allow this there)
oc adm policy add-scc-to-user anyuid -z default --as system:admin
# AND if this was a prod cluster we'd want to do this before making it live IF IMAGES ARE REBUILT TO NOT RUN AS ROOT
# for DEV/test is ok
# revert Minishift back to not allowing containers to run as root with this command:
#oc adm policy remove-scc-from-user anyuid -z default --as system:admin

# grant admin access to users FOR DEV ENVs
# https://github.com/minishift/minishift/issues/696
oc adm policy add-cluster-role-to-user cluster-admin admin --as=system:admin
oc adm policy add-cluster-role-to-user cluster-admin developer --as=system:admin
oc adm policy add-cluster-role-to-user cluster-admin myadmin --as=system:admin

minishift console

# call any/all requisite child NS/project platform apps to be created, deployed, etc.
./bin/create-myapp1-local-minishift.sh
./bin/create-myapp2-local-minishift.sh
./bin/create-myapp3-local-minishift.sh
