# mac with HinD notes


```sh
# `-p` -- run from inside `podman machine ssh` or outside -- can get to from everywhere
PORT=8080; podman run -p $PORT:$PORT --rm -it python:3-alpine sh -c 'python3 -c "import http.server; httpd = http.server.HTTPServer((\"0.0.0.0\", '$PORT'), http.server.SimpleHTTPRequestHandler); httpd.serve_forever()"'

# `--net=host` -- can get to from inside machine ssh -- but not from outside or browser
podman machine ssh
PORT=8080; podman run --net=host  --rm -it python:3-alpine sh -c 'python3 -c "import http.server; httpd = http.server.HTTPServer((\"0.0.0.0\", '$PORT'), http.server.SimpleHTTPRequestHandler); httpd.serve_forever()"'
```


## run locally
```sh
perl -i -pe 's/podman pull/#podman pull/' install.sh
export VERBOSE=1

podman build --tag ghcr.io/internetarchive/hind:main .

./install.sh
```

## research & development
```sh
# podman run --rm --privileged hind zsh -c 'podman run hello-world'
# helpful https://forums.docker.com/t/cgroup-v2-the-saga-continues/139329

# podman and nomad!
podman run --privileged --secret NOMAD_TOKEN,type=env -it --rm localhost/hind zsh -c 'echo +cpuset > /sys/fs/cgroup/cgroup.subtree_control; echo +cpuset > /sys/fs/cgroup/cgroup.controllers; nomad agent -config /etc/nomad.d & sleep 20; echo;echo;echo;nomad status; podman run hello-world'

podman run --cgroups disabled --privileged --secret NOMAD_TOKEN,type=env -it --rm localhost/hind zsh -c 'echo +cpuset > /sys/fs/cgroup/cgroup.subtree_control; echo +cpuset > /sys/fs/cgroup/cgroup.controllers; nomad agent -config /etc/nomad.d & sleep 20; echo;echo;echo;nomad status; podman run --cgroups disabled hello-world'

podman run --rm --privileged  -v $SOCK:/run/podman/podman.sock  podman podman -r ps -a
```


### other init/run args to try
- https://serverfault.com/questions/1053187/systemd-fails-to-run-in-a-docker-container-when-using-cgroupv2-cgroupns-priva
```sh
-v /sys/fs/cgroup:/sys/fs/cgroup:ro
--cgroupns=host
--cgroups disabled
```
previously had also tried: `-v /sys/fs/cgroup:/sys/fs/cgroup:rw`
