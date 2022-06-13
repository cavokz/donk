## DinD... DooD... DonK!

Dom's experiments with Docker, Kind, and Kubernetes.

## Container lab

A container image wraps the application and its dependencies so that the container runtime (eg. Docker) can execute it in controlled isolation. Because a completely isolated application would be useless, the container runtime offers options to break bits of such isolation.

Let's see what Docker runtime isolates by default.

#### PID space ✅ ####

Processes running on the host are not visible inside the container:

```shell
$ docker run --rm busybox ps
PID   USER     TIME  COMMAND
    1 root      0:00 ps
```

#### UNIX time-sharing system space (ie. hostname) ✅ ####

Host and container see a different hostname:

```shell
$ hostname
localhost
$ docker run --rm busybox hostname
c60412f4b438

```

#### Filesystem space ✅ ####

Host filesystem is not visible from within the container:

```shell
$ ls -x /
bin  boot  dev  doc  etc  home  lib  lost+found  mnt  proc  root  run  sbin  sys  tmp  usr   var
$ docker run --rm busybox ls -x /
bin  dev  etc  home  proc  root  sys  tmp  usr  var
```

#### UID/GID space ❌ ####

`root` inside the container is `root` also outside:

```shell
$ docker run --rm busybox whoami
root
$ docker run --rm -d busybox sleep 1234
615e88a9cbba7001f7fdede1e919e271161e4f50ac12f387630fcd2ad2f08da7
$ ps -eaf | grep sleep
root        4633    4612  0 16:53 ?        00:00:00 sleep 1234
```

`nobody` inside the container is `nobody` also outside:

```shell
$ docker run --rm --user nobody busybox whoami
nobody
$ docker run --rm --user nobody -d busybox sleep 4321
59c59c9e5ecfc7e3dff121ab2b71c35aa828dd09ea4a7c9743f345fd135893f4
$ ps -eaf | grep sleep
nobody      5549    5528  0 17:06 ?        00:00:00 sleep 4321
```

#### Network space ✅ ####

A service (eg. `nc` on port `1234`) bound on the host is accessible locally

```shell
$ nc -l -p 1234 &
$ echo 'Hi!' | nc -q0 localhost 1234
Hi!
```

Whereas it's not when bound inside the container

```shell
$ docker run --rm -it -d busybox nc -l -p 1234
...
$ echo 'Hi!' | nc -q0 localhost 1234
localhost [127.0.0.1] 1234 (?) : Connection refused
```

## Pod lab ##

A pod is an intermediate grouping between the host and the containers, containers running in the same pod share resources not accassible outside.

This is an example of pod definition ([busybox-pod.yml](busybox-pod.yml)) with two containers that would do nothing forever (`tail -f /dev/null`):

```
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
    - name: busybox-1
      image: busybox
      args: [ "tail", "-f", "/dev/null" ]
    - name: busybox-2
      image: busybox
      args: [ "tail", "-f", "/dev/null" ]
```


We use [Kind](https://kind.sigs.k8s.io/) to run a local cluster with one node:

```shell
$ kind create cluster
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.24.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/
```

We create the pod

```
$ kubectl apply -f busybox-pod.yml
pod/busybox created
```

Wait for it to become ready

```shell
$ kubectl wait pod busybox --for condition=Ready
pod/busybox condition met
```

Let's see what containers in a Kubernetes pod share by default.

#### PID space ❌ ####

Container 1:

```shell
$ kubectl exec -it busybox -c busybox-1 -- ps
PID   USER     TIME  COMMAND
    1 root      0:00 tail -f /dev/null
   13 root      0:00 ps
$ kubectl exec -it busybox -c busybox-1 -- ps
PID   USER     TIME  COMMAND
    1 root      0:00 tail -f /dev/null
   19 root      0:00 ps
```

Container 2:

```shell
$ kubectl exec -it busybox -c busybox-2 -- ps
PID   USER     TIME  COMMAND
    1 root      0:00 tail -f /dev/null
   13 root      0:00 ps
```

#### UNIX time-sharing system space ####


#### Filesystem space ❌ ####

```shell
$ kubectl exec -it busybox -c busybox-1 -- touch /busybox-1
$ kubectl exec -it busybox -c busybox-2 -- touch /busybox-2
$ kubectl exec -it busybox -c busybox-1 -- ls /
bin           etc           product_name  sys           var
busybox-1     home          product_uuid  tmp
dev           proc          root          usr
$ kubectl exec -it busybox -c busybox-2 -- ls /
bin           etc           product_name  sys           var
busybox-2     home          product_uuid  tmp
dev           proc          root          usr
```

#### UID/GID space ####

#### Network space ✅ ####

From one terminal (`busybox-1` listening to `localhost:1234`):

```shell
$ kubectl exec -it busybox -c busybox-1 -- nc -l -p 1234 localhost
Hi from busybox-2!
```

From another terminal (`busybox-2` connecting to `localhost:1234`), enter **Hi from busybox-2!** with the keyboard:

```shell
$ kubectl exec -it busybox -c busybox-2 -- nc localhost 1234
Hi from busybox-2!
```

## Resources

* [Using Docker-in-Docker for your CI or testing environment? Think twice.](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)
* [The danger of exposing docker.sock](https://dejandayoff.com/the-danger-of-exposing-docker.sock/)
* [Don't expose the Docker socket (not even to a container)](https://web.archive.org/web/20190623234615/https://www.lvh.io/posts/dont-expose-the-docker-socket-not-even-to-a-container.html)
