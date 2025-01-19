# Issues

This is an informal tracking of issues with the tests, remaining work items, and observations.

## Test Items

- [ ] Add more checks around systemd init, ensure that additional systemd units will start with Fedora in WSL2 such as apache or stateful containers (systemd-nspawn or moby)
- [x] Add checks for wayland functionality - added basic case with `foot` terminal emulator that is currently failing
- [x] PulseAudio functionality - works, unsure if we can/should get pipewire working as well
- [ ] GPU acceleration, depends on some DX12 work
  - https://bugzilla.redhat.com/show_bug.cgi?id=2115560
  - https://src.fedoraproject.org/rpms/mesa/pull-request/41



## Issues with Fedora in WSL

This is a work in progress, so not all issues are tracked in bugzilla yet. This is mostly a scratchpad so I don't lose track of things as we're testing. Some should probably go into a known issues list on the wiki that's linked to the change proposal later.

### Wayland and XWayland are not working - fix in progress

> Workaround: `ln -s /mnt/wslg/runtime-dir/wayland-0 $XDG_RUNTIME_DIR/wayland-0` . Jeremy is still looking at how to wrap this up into the image.


The `DISPLAY` and `WAYLAND_DISPLAY` variables are set, but something seems to be preventing Wayland from actually working. This isn't an area I'm used to debugging and need to follow up more. Ubuntu 22.04 works on the same system, booted into the same kernel. 

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

```
 $ foot
warn: config.c:3775: Noto Sans Regular: font does not appear to be monospace; check your config, or disable this warning by setting [tweak].font-monospace-warn=no
 err: wayland.c:1552: failed to connect to wayland; no compositor running?
```


### systemd units that fail to start

`journalctl` shows a variety of things that fail to start. I'm not sure which could be ignored, vs which may break stuff.

```
systemd-nsresourced[62]: bpf-lsm not supported, can't lock down user namespace.
systemd[220]: Failed to attach 220 to compat systemd cgroup '/user.slice/user-1000.slice/user@1000.service/init.scope', ignoring: Permission denied
```



### Audio investigations

If a user were to install a package such as `rhythmbox` or `firefox`, I'd expect the audio to work by default. They do, but I'm not sure if they are doing it in the best way. WSL sets `PULSE_SERVER="unix:/mnt/wslg/PulseServer"` so I guess that an app can just use it with the `pulseaudio-libs` dependency.

Maybe this is a good-enough state, but since Fedora is using pipewire by default I'd like that to work. That would also allow apps to rely on it for capturing output via the monitor_ sources.


pipewire seems to not be running, even if installed.

```
$ pw-dump
can't connect: Host is down
patrick@LAPTOP-E324PAUF:~$ wireplumber
Failed to connect to PipeWire
```