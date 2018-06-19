# minishift-local-poc

# Overview/Summary
* Creates LOCAL ENV minishift origin local cluster on MacOS / OSX with each requisite platform app/namespace created with child wrapper scripts.
    * uses the Minishift docker context
    * pulls private AWS ECR repo docker images into Minishift registry
    * creates, configures, and deploys our requisite projects/NS/apps.
    * works around docker for mac registry bug, etc.

# Deployment
* Edit the child create-myappN-local-minishift.sh scripts as needed.
* Execute the parent script
```
MINISHIFT-POC-LOCAL-DEPLOY.sh
```

* Details
    * The parent script calls child project/namespace/app wrapper creation scripts
        * create-myapp1-local-minishift.sh
        * create-myapp2-local-minishift.sh
        * create-myapp3-local-minishift.sh

    * This POC/DEV solution configures a minishift cluster with requisite configs such that future starts can just be `minishift start` and it will use the default profile configurations specified in the script.
    * Then the parent script spawns child script/processes--each child script/process configures requisite apps for our platform in separate minishift project/namespaces--with each app pulling/tagging their requisite docker images from private AWS ECR repo and pushing into the Minishift docker registry--i.e.:
        ```
        docker push 172.30.1.1:5000/myapp1-local/myapp
        ```

# For our use case
* we're working locally with minishift
* pulling from remote private AWS ECR repos
* tagging and pushing our images to the Minishift registry--AFAIK, minishift still considers this to be a remote docker registry. 
* The virtualbox driver just worked for us
    * I seem recall some other drivers missing plugins, configurations, etc., so just went with the VB driver as the default, but this can easily be changed.
    * JIC, the script will install the requisite minishift plugins, enable them, and also set admin creds

# Secrets and permission denied errors
* I had found another blog post from last year where they needed to use secrets else they were getting the permission denied errors (as was I) so set those up, and automated that process as well.  I'm not sure if that's the correct "Openshift/Minishift way," but it works for us so I went with it.

# Notes 
* This is a POC and suitable only for local/dev env's.

# Parent script stdout shows MS version, config, steps, etc.
```
$ minishift status
Does Not Exist

./local/bin/MINISHIFT-LOCAL-POC-DEPLOY.sh
No Minishift instance exists. New 'memory' setting will be applied on next 'minishift start'
No Minishift instance exists. New 'cpus' setting will be applied on next 'minishift start'
No Minishift instance exists. New 'vm-driver' setting will be applied on next 'minishift start'
No Minishift instance exists. New 'disk-size' setting will be applied on next 'minishift start'
Add-on 'anyuid' enabled
Add-on 'admin-user' enabled
Add-on 'registry-route' enabled
-- Starting profile 'minishift'
-- Checking if https://github.com is reachable ... OK
-- Checking if requested OpenShift version 'v3.9.0' is valid ... OK
-- Checking if requested OpenShift version 'v3.9.0' is supported ... OK
-- Checking if requested hypervisor 'virtualbox' is supported on this platform ... OK
-- Checking if VirtualBox is installed ... OK
-- Checking the ISO URL ... OK
-- Checking if provided oc flags are supported ... OK
-- Starting local OpenShift cluster using 'virtualbox' hypervisor ...
-- Minishift VM will be configured with ...
   Memory:    4 GB
   vCPUs :    4
   Disk size: 30 GB
...
   Importing 'openshift/origin:v3.9.0' ............. OK
   Importing 'openshift/origin-docker-registry:v3.9.0' ... OK
   Importing 'openshift/origin-haproxy-router:v3.9.0' ... OK
-- OpenShift cluster will be configured with ...
   Version: v3.9.0
-- Copying oc binary from the OpenShift container image to VM . OK
-- Starting OpenShift cluster ..............................
Using Docker shared volumes for OpenShift volumes
Using public hostname IP 192.168.99.100 as the host IP
Using 192.168.99.100 as the server IP
Starting OpenShift using openshift/origin:v3.9.0 ...
OpenShift server started.

The server is accessible via web console at:
    https://192.168.99.100:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin

-- Applying addon 'admin-user':..
-- Applying addon 'anyuid':.
 Add-on 'anyuid' changed the default security context constraints to allow pods to run as any user.
 Per default OpenShift runs containers using an arbitrarily assigned user ID.
 Refer to https://docs.openshift.org/latest/architecture/additional_concepts/authorization.html#security-context-constraints and
 https://docs.openshift.org/latest/creating_images/guidelines.html#openshift-origin-specific-guidelines for more information.
-- Applying addon 'registry-route':........
Add-on 'registry-route' created docker-registry route. Please run following commands to login to the OpenShift docker registry:
$ eval $(minishift docker-env)
$ eval $(minishift oc-env)

If your deployed version of OpenShift is < 3.7.0 use.
$ docker login -u developer -p `oc whoami -t` docker-registry-default.192.168.99.100.nip.io:443

If your deployed version of OpenShift is >= 3.7.0 use.
$ docker login -u developer -p `oc whoami -t` docker-registry-default.192.168.99.100.nip.io
Logged into "https://192.168.99.100:8443" as "developer" using the token provided.

You have one project on this server: "myproject"

Using project "myproject".
scc "anyuid" added to: ["system:serviceaccount:myproject:default"]
cluster role "cluster-admin" added: "admin"
cluster role "cluster-admin" added: "developer"
cluster role "cluster-admin" added: "myadmin"
Opening the OpenShift Web console in the default browser...
error: A project named "id-local" does not exist on "https://192.168.99.100:8443".
Your projects are:
* default
* kube-public
* kube-system
* My Project (myproject)
* openshift
* openshift-infra
* openshift-node
* openshift-web-console
To see projects on another server, pass '--server=<server>'.

# NOTE: parent script now starts calling child scripts for each project/namespace...
# Parent script now calls next child wrapper/script for myapp1...
# Parent script now calls next child wrapper/script for myapp2...
```

# After all child wrapper NS/projects are completed
* Validate your myapp{1..n}
```
oc get all -n myapp1-local
NAME                      REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfigs/myapp1   1          1         1         config,image(myapp1-client:latest)

NAME                        DOCKER REPO                                TAGS      UPDATED
imagestreams/myapp1          172.30.1.1:5000/myapp1-local/myapp1          latest
imagestreams/myapp1-client   172.30.1.1:5000/myapp1-local/myapp1-client   latest    40 minutes ago

NAME           HOST/PORT                                 PATH      SERVICES   PORT      TERMINATION   WILDCARD
routes/myapp1   myapp1-myapp1-local.192.168.99.100.nip.io             myapp1      80-tcp                  None

NAME               READY     STATUS    RESTARTS   AGE
po/myapp1-1-z78x8   1/1       Running   0          40m

NAME         DESIRED   CURRENT   READY     AGE
rc/myapp1-1   1         1         1         40m

NAME        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
svc/myapp1   ClusterIP   172.30.229.232   <none>        80/TCP    40m
```