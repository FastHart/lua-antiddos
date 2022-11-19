### Description

This is a sample lua script for nginx or openresty to block suspected IP's

Script will ban IP if too many hostames was requested in a one-hour window from this IP.

Have a black and white lists, write log to the nginx  error log.

Script use nginx shared dictionary to store counters and nginx variables for config and white/black lists.  

Feel free to use this script as a starting point to write your own scripts.

### Usage

Put scripts in `/etc/nginx/lua-antiddos`

Add to `/etc/nginx.conf` in `http` block:

```    
    # start anti ddos
    lua_shared_dict ddos_ip_new   10m;
    lua_shared_dict ddos_ip_white 10m;
    lua_shared_dict ddos_ip_black 10m;
    init_by_lua_file lua-antiddos/anti_ddos_load.lua;
    # end anti ddos
```
Add somewhere in location block:

```
    # Start anti ddos
    set $ban_treshhold 10;
    set $ttl_new       3600;
    set $ttl_white     60;
    set $ttl_black     3600;
    set $debug         true;
    set $test_mode     true;
    access_by_lua_file  lua-antiddos/anti_ddos.lua;
    # End of anti ddos
```
ban_treshhold -- how many hosts allowed to be requested from one IP in one hour window  
ttl_new       -- time to remember new ip-hostname combination in seconds (should be 3600)  
ttl_white     -- time to whitelist (currently not used)  
ttl_black     -- time to blaklist in seconds  
debug         -- boolean (make some additional output to error log if true)  
test_mode     -- boolean (always respond OK if true)  


