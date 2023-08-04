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
- `eno1` is interface device to use
- `gPTP.cfg` is the configuration file
- `step_threshold` is the maximum offset the servo will correct by changing the clock frequency (phase when using nullf servo) instead of stepping the clock
- `m` is used to print messages to stdout

### nsm
NetSync Monitor (NSM) client:
```bash
$ sudo linuxptp-rt.nsm -i eno1 -f /snap/linuxptp-rt/current/etc/ptp4l.conf 
```

### pmc
Synchronize the system clock:
```bash
$ sudo linuxptp-rt.pmc -u -b 0 -t 1 "SET GRANDMASTER_SETTINGS_NP clockClass 248 \
        clockAccuracy 0xfe offsetScaledLogVariance 0xffff \
        currentUtcOffset 37 leap61 0 leap59 0 currentUtcOffsetValid 1 \
        ptpTimescale 1 timeTraceable 1 frequencyTraceable 0 \
        timeSource 0xa0"
sending: SET GRANDMASTER_SETTINGS_NP
```

where:
- `u` is used to select the Unix Domain Socket transport
- `b` is used to specify the boundary hops value in sent messages
- `t` is used to specify the transport specific field in sent messages as a hexadecimal number.


### phc2sys
Synchronize the system clock with PHC:
```bash
$ sudo linuxptp-rt.phc2sys -s eno1 -c CLOCK_REALTIME --step_threshold=1 --transportSpecific=1 -w -m
phc2sys[39606.945]: Waiting for ptp4l...
```

where:
- `s` is the source clock
- `c` is the time sink by device
- `step_threshold` is the step threshold of the servo
- `transportSpecific` is the transport specific field. 
- `w` waits until ptp4l is in a synchronized state
- `m` prints messages to the standard output

### hwstamp-ctl
Enable hardware time stamping:
```bash
$ sudo linuxptp-rt.hwstamp-ctl -i eno1 -t 1 -r 9
current settings:
tx_type 1
rx_filter 12
new settings:
tx_type 1
rx_filter 12
```
where:
- `eno1` is interface device to use
- `t` is whether enable or disable hardware time stamping for outgoing packets
- `r` is the type of incoming packets should be time stamped

### phc_ctl
Control a PHC clock:
```bash
$ sudo linuxptp-rt.phc-ctl eno1 get
phc_ctl[45040.084]: clock time is 1689781163.846408401 or Wed Jul 19 17:39:23 2023
```
where:
- `eno1` is the interface device to use
- `get` is the command to get the current time of the PHC clock device



### timemaster
Run Network Time Protocol (NTP) with PTP as reference clocks:
```bash
sudo linuxptp-rt.timemaster -f /snap/linuxptp-rt/current/etc/timemaster.conf 
```

### ts2phc
Synchronize one or more PHC using external time stamps:

```bash
$ sudo linuxptp-rt.ts2phc -c eno1 -m
ts2phc[70509.819]: cannot open /dev/ptp0 for eno1: Operation not permitted
```
TBA

### tz2alt
Monitor daylight savings time changes and publishes them to PTP stack:
```bash
$ sudo linuxptp-rt.tz2alt -z Europe/Berlin --leapfile /usr/share/zoneinfo/leap-seconds.list
tz2alt[70278.242]: truncating time zone display name from Europe/Berlin to Berlin
tz2alt[70278.245]: next discontinuity Wed Jul 26 17:03:22 2023 Europe/Berlin
```
where:
- `z` is the timezone
- `leapfile` is the path to the current leap seconds definition file


## Configuration files
The configuration files packaged in the snap are sourced from two locations:
- LinuxPTP's source repo
- This repo (ptp4l.conf and timemaster.conf). These files have been taken from the linuxptp_3.1.1-3_amd64.deb package from Ubuntu archives.


## References
 - https://manpages.debian.org/unstable/linuxptp/index.html
 - https://tsn.readthedocs.io/timesync.html
