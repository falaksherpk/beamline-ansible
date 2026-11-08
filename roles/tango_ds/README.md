tango_ds
========

The Tango device-server host of the lab (`tango-ds.beamline`; handbook Part 3, Ch23 and
Ch29; Part 4, Ch35). The Tango Database itself is `roles/tango_db`.

What it does
------------

- **Tango client side and tools (Ch23):** `tango-common`, `libtango-tools`, `socat`,
  debugging tools; `TANGO_HOST` in `/etc/environment`; Jive from conda-forge. Redis is
  removed (Ch27).
- **The device servers from the lab's apt repository (Ch35):** `beamline-tango-devices`
  (the five servers, the Sardana controllers, and their own hash-locked runtime in
  `/opt/beamline-tango`) and `beamline-tango-simulators`, at `tango_ds_package_version`,
  held. Both are released by `tango-devices`' tag pipeline (Ch34).
- **Registration (Ch29, tag `tango_ds_register`):** `tango_ds_servers` lists the five
  device servers, `tango_ds_sardana_servers` the Pool and MacroServer.
  `/usr/local/sbin/tango-ds-register` adds a server or device the database lacks and
  writes only the properties that differ; memorized attribute values are never touched.
  In check mode a difference is reported as a change. The role's scripts run on the
  package's runtime.
- **Services (Ch35, tag `tango_ds_services`):** instances of the package's template units,
  one per process: `tango-<server>@<instance>` for the servers (the instance is the
  Tango instance name) and `tango-sim-<simulator>@<instance>` for the simulators, all
  `PartOf=` and `WantedBy=` the package's `tango-lab.target`. The role writes each
  instance's site data, `/etc/beamline-tango/<template>-<instance>.env` (database,
  endpoint host, ports, log level; the simulators' ports), before it enables any, and a
  drop-in `50-beamline-site.conf` for what an instance starts after here (each device
  after its simulator, the magnet bound to its link, the Pool after the magnet and the
  Faraday cup). It restarts every instance after a new release, and otherwise only those
  whose site data, drop-in or registration changed.
- **Firewall (Ch29, tag `tango_ds_firewall`):** each server has a fixed CORBA port
  (`-ORBendPoint`) and fixed ZeroMQ heartbeat and event ports (`TANGO_ZMQ_*_PORT`),
  bound to the host's lab address; the three blocks are opened to `tango_ds_allowed_from`.
  Simulator ports stay on 127.0.0.1.
- **The Prometheus exporter (Ch36, tag `tango_ds_exporter`):** `tango-exporter@linac`
  from the package (1.1.0), not part of `tango-lab.target`. Its site data lists the
  devices (this role's servers, Sardana's servers and elements, HDB++'s two servers), the
  attributes and the HDB++ EventSubscriber; it serves `/metrics` on the lab address,
  port `tango_ds_exporter_port`, which ufw opens to the Prometheus host only. Restarted
  after a new release or new site data.
- **Sardana's elements (Ch31, tag `tango_ds_sardana_elements`) and attribute
  configuration (Ch32, tag `tango_ds_attribute_config`):** compared, then created or set
  where they differ.
- **Part 3's layout, removed once (Ch35):** the role-rendered units and target in
  `/etc/systemd/system`, PyTango, Sardana and the dev tools in the system Python's pip
  tree, `python3-pip`, the checkout `/opt/tango-devices`, and the readiness helpers in
  `/usr/local/sbin`. On a host built after Ch35 these tasks find nothing.

Operating it
------------

    systemctl list-units 'tango-*'                 # every instance and the target
    sudo systemctl restart tango-lab.target         # everything, in dependency order
    sudo journalctl -u tango-magnet@q1 -f           # one server's log, its own lines included
    systemctl cat tango-magnet@q1                   # the package's unit and this site's drop-in

A new release: set `tango_ds_package_version` to it and run the play; the role installs
it and restarts every instance. Rolling back is the same change back, with the previous
release's `.deb` files from its kept pipeline artifacts installed first (the repository
keeps one version; handbook Ch35). Memorized values behave as in the device chapters:
the vacuum gauge's memorized `PumpStatus` starts the pump at every start of its server.

License
-------

MIT-0 (as the tasks file).
