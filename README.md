# LinuxPTP Snap


### Build
```bash
snapcraft -v
```

### Install
```bash
snap install --dangerous *.snap
```

### Configure
The default config files are placed under `/snap/linuxptp-rt/current/etc`:
```
/snap/linuxptp-rt/current/etc
├── automotive-master.cfg
├── automotive-slave.cfg
├── default.cfg
├── E2E-TC.cfg
├── G.8265.1.cfg
├── G.8275.1.cfg
├── G.8275.2.cfg
├── gPTP.cfg
├── P2P-TC.cfg
├── ptp4l.conf
├── snmpd.conf
├── timemaster.conf
├── ts2phc-generic.cfg
├── ts2phc-TC.cfg
├── UNICAST-MASTER.cfg
└── UNICAST-SLAVE.cfg
```
The configuration files are sourced from two locations:
- LinuxPTP's [source code](https://github.com/richardcochran/linuxptp)
- This repo (ptp4l.conf and timemaster.conf). These files have been taken from the linuxptp_3.1.1-3_amd64.deb package from Ubuntu archives.

Grant access to necessary resources:
```bash
# Access to network setting
snap connect linuxptp-rt:network-control
# Access to system date and time
snap connect linuxptp-rt:time-control

# Access to system logs and data
snap connect linuxptp-rt:system-backup  
snap connect linuxptp-rt:log-observe   

# Access to PTP subsystem and files
snap connect linuxptp-rt:ptp
snap connect linuxptp-rt:system-dev-pts
snap connect linuxptp-rt:system-dev-ptp0 
snap connect linuxptp-rt:system-run-ptp4l
snap connect linuxptp-rt:system-run
```

Add [aliases](https://snapcraft.io/docs/commands-and-aliases) to run the commands without the namespace.For example:
```bash
$ snap alias linuxptp-rt.ptp4l ptp4l
Added:
  - linuxptp-rt.ptp4l as ptp4l

$ which ptp4l
/snap/bin/ptp4l

$ ptp4l -v
4.0
```


For usage examples, refer to the wiki.

## To Do
- [ ] Fix ts2phc permission error - see examples in wiki
- [ ] Check ptp4l and ptp4lro paths - config files point to /var/run/* but system interface is for /run/*
- [ ] Clarify chronyd and ntpd dependencies for timemaster - see its config file

## References
 - https://manpages.debian.org/unstable/linuxptp/index.html
 - https://tsn.readthedocs.io/timesync.html
