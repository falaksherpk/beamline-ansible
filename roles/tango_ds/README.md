tango_ds
========

The Tango device-server host of the lab (`tango-ds.beamline`; handbook Part 3, Ch23 and
Ch29). The Tango Database itself is `roles/tango_db`.

What it does
------------

- **Tango client side and tools (Ch23):** `tango-common`, `libtango-tools`, `socat`,
  debugging tools; PyTango and the devices' Python packages, pinned to the same versions
  as `tango-devices`' `ci/Dockerfile`; `TANGO_HOST` in `/etc/environment`; Jive from
  conda-forge. Redis is removed (Ch27).
- **Registration (Ch29, tag `tango_ds_register`):** `tango_ds_servers` lists the five
  device servers. `/usr/local/sbin/tango-ds-register` adds a server or device the
  database lacks and writes only the properties that differ; memorized attribute values
  are never touched. In check mode a difference is reported as a change.
- **Services (Ch29, tag `tango_ds_services`):** one systemd unit per process, from one
  template: `tango-<name>.service` for the servers and for the simulators in
  `tango_ds_simulators`, all `PartOf=` and `WantedBy=` `tango-lab.target`. They run as
  `tango`, with `Restart=on-failure` and `roles/healthcheck`'s hardening set (servers
  also need `AF_NETLINK`). Simulators report ready through
  `/usr/local/sbin/tango-ds-wait` before the units ordered after them start. The magnet's
  units are bound to its `socat` unit; every other device heals by itself when its
  simulator returns.
- **Firewall (Ch29, tag `tango_ds_firewall`):** each server has a fixed CORBA port
  (`-ORBendPoint`) and fixed ZeroMQ heartbeat and event ports (`TANGO_ZMQ_*_PORT`),
  bound to the host's lab address; the three blocks are opened to `tango_ds_allowed_from`.
  Simulator ports stay on 127.0.0.1.

Operating it
------------

    sudo systemctl status 'tango-*'          # every unit
    sudo systemctl restart tango-lab.target  # everything, in dependency order
    sudo journalctl -u tango-magnet -f       # one server's log, its own lines included

The code in `/opt/tango-devices` is pulled by hand with the read-only deploy token
(handbook Ch23); after a pull, restart the affected units. Memorized values behave as in
the device chapters: the vacuum gauge's memorized `PumpStatus` starts the pump at every
start of its server.

License
-------

MIT-0 (as the tasks file).
