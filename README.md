# LinuxPTP Snap

## To Do
- Fix ts2phc permission error - see examples
- Check ptp4l and ptp4lro paths - config files point to /var/run/* but system interface is for /run/*
- Clarify chronyd and ntpd dependencies for timemaster - see its config file

## Build
```bash
snapcraft -v
```

## Install
```bash
snap install --devmode *.snap
```

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

## Grant access to resources
Connect interfaces to access desired resources:
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

## Set an alias (optional)

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

## Usage examples

**In the following examples, `eno1` is the Ethernet interface name.**

### ptp4l
Synchronize the PTP Hardware Clock (PHC):
```bash
$ sudo linuxptp-rt.ptp4l -i eno1 -f /snap/linuxptp-rt/current/etc/gPTP.cfg --step_threshold=1 -m
ptp4l[10992.160]: selected /dev/ptp0 as PTP clock
ptp4l[10992.246]: port 1 (eno1): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[10992.247]: port 0 (/var/run/ptp4l): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[10992.247]: port 0 (/var/run/ptp4lro): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[10995.795]: port 1 (eno1): LISTENING to MASTER on ANNOUNCE_RECEIPT_TIMEOUT_EXPIRES
ptp4l[10995.795]: selected local clock 04421a.fffe.078056 as best master
ptp4l[10995.795]: port 1 (eno1): assuming the grand master role
```

where:
- `-f` is set to the gPTP configuration file in the snap

### nsm
NetSync Monitor (NSM) client:
```bash
$ sudo linuxptp-rt.nsm -i eno1 -f /snap/linuxptp-rt/current/etc/ptp4l.conf 
```


### pmc
Synchronize the system clock:
```bash
$ sudo linuxptp-rt.pmc -i /run/snap.linuxptp-rt/pmc.$pid -u -b 0 -t 1 "SET GRANDMASTER_SETTINGS_NP clockClass 248 \
        clockAccuracy 0xfe offsetScaledLogVariance 0xffff \
        currentUtcOffset 37 leap61 0 leap59 0 currentUtcOffsetValid 1 \
        ptpTimescale 1 timeTraceable 1 frequencyTraceable 0 \
        timeSource 0xa0"
sending: SET GRANDMASTER_SETTINGS_NP
```

where:
- `-i` is set to change the default interface to use for UDS.


### ❌ phc2sys
Run `ptp4l` and synchronize the system clock with PHC:
```bash
$ sudo linuxptp-rt.phc2sys -s eno1 -c CLOCK_REALTIME --step_threshold=1 --transportSpecific=1 -w -m
phc2sys[21132.098]: uds: bind failed: Permission denied
phc2sys[21132.098]: failed to open transport
phc2sys[21132.098]: failed to create pmc
```

🚩 By default, phc2sys uses `/run/phc2sys.$pid` as the default path to UDS interface. This is not allowed within the snap confinement. There is no [CLI flag or configuration field](https://www.mankier.com/8/phc2sys) to override it. The path is hard-coded [here](https://github.com/richardcochran/linuxptp/blob/master/phc2sys.c#L1445).


### hwstamp-ctl
Enable hardware timestamping:
```bash
$ sudo linuxptp-rt.hwstamp-ctl -i eno1 -t 1 -r 9
current settings:
tx_type 1
rx_filter 12
new settings:
tx_type 1
rx_filter 12
```

### phc_ctl
Control a PHC clock:
```bash
$ sudo linuxptp-rt.phc-ctl eno1 get
phc_ctl[45040.084]: clock time is 1689781163.846408401 or Wed Jul 19 17:39:23 2023
```

### 🚧 timemaster
Run Network Time Protocol (NTP) with PTP as reference clocks:
```bash
$ sudo linuxptp-rt.timemaster -f /snap/linuxptp-rt/current/etc/timemaster.conf -m
timemaster[22360.873]: failed to create /var/run/timemaster: Permission denied
timemaster[22360.873]: exiting
```

### 🚧 ts2phc
Synchronize one or more PHC using external time stamps:

```bash
$ sudo linuxptp-rt.ts2phc -c eno1 -m
ts2phc[70509.819]: cannot open /dev/ptp0 for eno1: Operation not permitted
```

### 🚧 tz2alt
Monitor daylight savings time changes and publishes them to PTP stack:
```bash
$ sudo linuxptp-rt.tz2alt -z Europe/Berlin --leapfile /usr/share/zoneinfo/leap-seconds.list
tz2alt[70278.242]: truncating time zone display name from Europe/Berlin to Berlin
tz2alt[70278.245]: next discontinuity Wed Jul 26 17:03:22 2023 Europe/Berlin
```
where:
- `z` is the timezone
- `leapfile` is the path to the current leap seconds definition file


## References
 - https://manpages.debian.org/unstable/linuxptp/index.html
 - https://tsn.readthedocs.io/timesync.html
