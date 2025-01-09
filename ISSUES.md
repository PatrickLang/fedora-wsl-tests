# Issues

This is an informal tracking of issues with the tests, remaining work items, and observations.

## Test Items

- [ ] Add more checks around systemd init
- [ ] Add checks for wayland functionality



## Issues with Fedora in WSL

This is a work in progress, so not all issues are tracked in bugzilla yet. This is mostly a scratchpad so I don't lose track of things as we're testing. Some should probably go into a known issues list on the wiki that's linked to the change proposal later.

### Wayland is not working

The `DISPLAY` variable is set, but something seems to be preventing Wayland from actually working. This isn't an area I'm used to debugging and need to follow up more. Ubuntu 22.04 works on the same system, booted into the same kernel. 

```
$ waycheck
Failed to create wl_display (No such file or directory)
qt.qpa.plugin: Could not load the Qt platform plugin "wayland" in "" even though it was found.
qt.qpa.xcb: could not connect to display :0
qt.qpa.plugin: From 6.5.0, xcb-cursor0 or libxcb-cursor0 is needed to load the Qt xcb platform plugin.
qt.qpa.plugin: Could not load the Qt platform plugin "xcb" in "" even though it was found.
This application failed to start because no Qt platform plugin could be initialized. Reinstalling the application may fix this problem.

Available platform plugins are: xcb, minimalegl, eglfs, linuxfb, vnc, offscreen, wayland-egl, wayland, minimal, vkkhrdisplay.

Aborted (core dumped)
```


```
$ Xwayland
could not connect to wayland server
(EE)
Fatal server error:
(EE) Couldn't add screen
(EE)
```


### systemd units that fail to start

`journalctl` shows a variety of things that fail to start.

```
systemd-nsresourced[62]: bpf-lsm not supported, can't lock down user namespace.
systemd[220]: Failed to attach 220 to compat systemd cgroup '/user.slice/user-1000.slice/user@1000.service/init.scope', ignoring: Permission denied
```