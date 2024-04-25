# LinuxPTP Snap


### Build
```bash
snapcraft -v
```

### Install
```bash
sudo snap install --dangerous ./linuxptp-rt_*.snap
```

### Configure snap

Grant access to necessary resources:
```bash
# Access to network setting
sudo snap connect linuxptp-rt:network-control
# Access to system date and time
sudo snap connect linuxptp-rt:time-control

# Access to system logs and data
sudo snap connect linuxptp-rt:system-backup
sudo snap connect linuxptp-rt:log-observe

# Access to PTP subsystem and files
sudo snap connect linuxptp-rt:ptp
```

(optional) Add [aliases](https://snapcraft.io/docs/commands-and-aliases) to run the commands without the namespace. For example:
```bash
$ snap alias linuxptp-rt.ptp4l ptp4l
Added:
  - linuxptp-rt.ptp4l as ptp4l

$ which ptp4l
/snap/bin/ptp4l

$ ptp4l -v
4.0
```

### Configure linuxptp
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
├── snap.cfg
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

> Note: linuxptp uses unix domain sockets for inter-process communication. By default it stores the UDS file handles under `/run` or `/var/run`. Neither of these two system directories can be accessed from inside a strictly confined snap. We therefore change these UDSs to be created under `/run/snap.linuxptp-rt/`, which is a special directory that may be accessed by the snap. Please keep this in mind when running any of the linuxptp utilities.

## Usage examples

**In the following examples, `eth0` is the Ethernet interface name.**

### ptp4l
Synchronize the PTP Hardware Clock (PHC):
```bash
$ sudo linuxptp-rt.ptp4l -i eth0 -f /snap/linuxptp-rt/current/etc/gPTP.cfg --step_threshold=1 -m
ptp4l[5357.320]: selected /dev/ptp0 as PTP clock
ptp4l[5357.331]: port 1 (eth0): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[5357.331]: port 0 (/run/snap.linuxptp-rt/ptp4l): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[5357.331]: port 0 (/run/snap.linuxptp-rt/ptp4lro): INITIALIZING to LISTENING on INIT_COMPLETE
ptp4l[5361.107]: port 1 (eth0): LISTENING to MASTER on ANNOUNCE_RECEIPT_TIMEOUT_EXPIRES
ptp4l[5361.107]: selected local clock 2ccf67.fffe.1cbba1 as best master
ptp4l[5361.107]: port 1 (eth0): assuming the grand master role
^C
```

where:
- `-f` is set to the gPTP configuration file in the snap

### nsm
NetSync Monitor (NSM) client:
```bash
$ sudo linuxptp-rt.nsm -i eth0 -f /snap/linuxptp-rt/current/etc/ptp4l.conf
```


### pmc
Configure the system's UTC-TAI offset (leap seconds):
```bash
$ sudo linuxptp-rt.pmc -u -b 0 -t 1 \
  "SET GRANDMASTER_SETTINGS_NP clockClass 248 \
  clockAccuracy 0xfe offsetScaledLogVariance 0xffff \
  currentUtcOffset 37 leap61 0 leap59 0 currentUtcOffsetValid 1 \
  ptpTimescale 1 timeTraceable 1 frequencyTraceable 0 \
  timeSource 0xa0"
```

where:
- `-u` specifies the usage of Unix Domain Sockets for inter process communication

The above `SET` command should output a response like below. You can also query the settings by running:

```bash
$ sudo linuxptp-rt.pmc -u -b 0 -t 1 "GET GRANDMASTER_SETTINGS_NP"`
```

```
sending: SET GRANDMASTER_SETTINGS_NP
	2ccf67.fffe.1cbba1-0 seq 0 RESPONSE MANAGEMENT GRANDMASTER_SETTINGS_NP
		clockClass              248
		clockAccuracy           0xfe
		offsetScaledLogVariance 0xffff
		currentUtcOffset        37
		leap61                  0
		leap59                  0
		currentUtcOffsetValid   1
		ptpTimescale            1
		timeTraceable           1
		frequencyTraceable      0
		timeSource              0xa0
```


### phc2sys
Run `ptp4l` and synchronize the system clock with PHC:
```bash
$ sudo linuxptp-rt.phc2sys -s eth0 -c CLOCK_REALTIME --step_threshold=1 --transportSpecific=1 -w -m
phc2sys[2429.376]: CLOCK_REALTIME phc offset 37488402189 s0 freq    +781 delay      0
phc2sys[2430.376]: CLOCK_REALTIME phc offset 37488450430 s1 freq  +48990 delay      0
phc2sys[2431.377]: CLOCK_REALTIME phc offset 37498466839 s0 freq  +48990 delay      0
phc2sys[2432.377]: CLOCK_REALTIME phc offset 37498427594 s0 freq  +48990 delay      0
phc2sys[2433.378]: CLOCK_REALTIME phc offset 37498388319 s1 freq   +9735 delay      0
^C
```


### hwstamp-ctl
Enable hardware timestamping:
```bash
$ sudo linuxptp-rt.hwstamp-ctl -i eth0 -t 1 -r 9
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
$ sudo linuxptp-rt.phc-ctl eth0 get
phc_ctl[45040.084]: clock time is 1689781163.846408401 or Wed Jul 19 17:39:23 2023
```

### 🚧 timemaster
Run Network Time Protocol (NTP) with PTP as reference clocks:
```bash
$ sudo linuxptp-rt.timemaster -f /snap/linuxptp-rt/current/etc/timemaster.conf -m
timemaster[6519.236]: failed to spawn /usr/sbin/chronyd: No such file or directory
timemaster[6519.236]: exiting
```

> Note: A strictly confined snap can not access and control executables on the host. Adding Chrony and NTP to this snap is a possible workaround, but a better solution is to use the standalone Chrony or NTP snaps, and setting up a connection between them. This is currently out of scope and will be looked at in the future. See issue #9.

### 🚧 ts2phc
Synchronize one or more PHC using external time stamps:

```bash
$ sudo linuxptp-rt.ts2phc -c eth0 -m
ts2phc[6307.476]: PTP_EXTTS_REQUEST2 failed: Operation not supported
failed to initialize PPS sinks
```

Raspberry Pi 5:
```bash
$ sudo linuxptp-rt.ts2phc -c eth0 -m
ts2phc[80181.099]: PTP_EXTTS_REQUEST2 failed: Invalid argument
ts2phc[80181.099]: PTP_EXTTS_REQUEST2 failed: Invalid argument
failed to initialize PPS sinks
ts2phc[80181.099]: PTP_EXTTS_REQUEST2 failed: Invalid argument
```

> Note: Special hardware is required to use `ts2phc`. See issue #8.

### tz2alt
Monitor daylight savings time changes and publishes them to PTP stack:
```bash
$ sudo linuxptp-rt.tz2alt -z Europe/Berlin --leapfile /usr/share/zoneinfo/leap-seconds.list
tz2alt[70278.242]: truncating time zone display name from Europe/Berlin to Berlin
tz2alt[70278.245]: next discontinuity Wed Jul 26 17:03:22 2023 Europe/Berlin
```

## Examples
### gPTP
Master and slave, autoselected using the Best Master Clock Algorithm (BMCA)
```
$ sudo linuxptp-rt.ptp4l -i eth0 -f /snap/linuxptp-rt/current/etc/gPTP.cfg --step_threshold=1 -m
```

Synchronise the system clock
```
$ sudo linuxptp-rt.phc2sys -s eth0 -c CLOCK_REALTIME --step_threshold=1 --transportSpecific=1 -w -m
```

### Automotive
Master
```
$ sudo linuxptp-rt.ptp4l -i eth0 --step_threshold=1 -m \
  -f /snap/linuxptp-rt/current/etc/automotive-master.cfg
```

Slave
```
$ sudo linuxptp-rt.ptp4l -i eth0 --step_threshold=1 -m \
  -f /snap/linuxptp-rt/current/etc/automotive-slave.cfg
```

Synchronise system clock
```
$ sudo linuxptp-rt.phc2sys -s eth0 -O 0 -c CLOCK_REALTIME --step_threshold=1 \
  --transportSpecific=1 -m --first_step_threshold=0.0 -w
```

## Raspberry Pi 5

The Raspberry Pi 5 supports PTP. It however does not work with the default `gPTP.cfg` file, as it specifies a minimum neighbour propagation delay of 800ns. We have seen delays of around 17000ns between two Pis connected back to back.

One can remove the line `neighborPropDelayThresh 800` from `gPTP.cfg` to get it to work. Or alternatively specify a large enough threshold on the command line:
```bash
$ sudo linuxptp-rt.ptp4l -i eth0 -f /snap/linuxptp-rt/current/etc/gPTP.cfg \
  --step_threshold=1 -m --neighborPropDelayThresh 20000
```

Note that this may have side effects, but during our testing two Pi 5's did synchronise their clocks to withing 20ns of each other.

## References
 - https://manpages.debian.org/unstable/linuxptp/index.html
 - https://tsn.readthedocs.io/timesync.html
