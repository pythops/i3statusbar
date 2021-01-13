# A custom i3 bar

### why creating a status bar from scratch ?
The other alternatives are complex to configure. So I created this one based on bash, which is simple and very easy to customize.

### Plugins
- battery
- cpu
- disk
- docker
- memory
- network
- virtualbox
- volume

### Installation
You need to have those packages installed in your system
```
- acpi
- alsa-utils
- bc
- docker
- hwinfo
- sysstat
- virtualbox
- wireless-tools
```

Then update the i3 config
```
# ~/.config/i3/config
...
bar {
  status_command /path/to/i3statusbar.sh
}
...
```

### TODO
- [ ] Implement bandwidth plugin

## License
GPLv3
