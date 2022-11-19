--
-- This script: Bans IP for a ttl_black if it have requested more than ban_treshhold sites in a one hour
--
local ngx = require "ngx"
local ip_new = ngx.shared.ddos_ip_new
local ip_white = ngx.shared.ddos_ip_white
local ip_black = ngx.shared.ddos_ip_black

-- Load variables from nginx config
local ban_treshhold = tonumber(ngx.var.ban_treshhold) -- how many new hosts allowed to request from one IP in one hour
local ttl_new       = tonumber(ngx.var.ttl_new)       -- time to remember new ip-hostname combination in seconds (should be 3600)
local ttl_white     = tonumber(ngx.var.ttl_white)     -- time to whitelist (currently not used)
local ttl_black     = tonumber(ngx.var.ttl_black)     -- time to blaklist in seconds
stringtoboolean={ ["true"]=true, ["false"]=false }
local debug         = stringtoboolean[ngx.var.debug]         -- boolean
local test_mode     = stringtoboolean[ngx.var.test_mode]     -- boolean

-- case insensitive
local static = {
  "ico",
  "gif",
  "css",
  "txt",
  "jpeg",
  "jpg",
  "js",
  "xml"
}

-- case insensitive
local white_user_agents = {
  "curl",
  "google",
  "yandex",
  "PetalBot",
  "Ahref",
  "DotBot",
  "UptimeRobot",
  "Baidu",
  "Semrush"
}

local request_uri = ngx.var.request_uri
local user_agent = ngx.var.http_user_agent
local request_host = ngx.var.http_host 
local ip = ngx.var.remote_addr
local ip_host = ip.."_"..request_host
local time = os.date("*t")
local ip_hour = ip.."_"..time.hour

function is_static_content()
  for i=1,#static do
    local regexp = static[i]
    if string.match(request_uri, regexp)
    then
      if debug then ngx.log(ngx.ERR, "Requested static content from IP: "..ip) end
      return true
    end
  end
  return false
end

function match_regex_list(str, regexlist)
  for i=1,#regexlist do
    local regexp = regexlist[i]
    -- make case insensitive
    str = string.lower(str)
    regexp = string.lower(regexp)
    if string.match(str, regexp) then return true end
  end
  return false
end

function is_good_user_agent()
  -- case insensitive
  if match_regex_list(user_agent, white_user_agents)
  then
    if debug then ngx.log(ngx.ERR, "Request from allowed user_agent: "..user_agent) end
    return true
  end
  return false
end

function is_white()
  if ip_white:get(ip)
  then
    if debug then ngx.log(ngx.ERR, "IP in dinamic white list: "..ip) end
    return true
  end
  if whitelist[ip] == 1 then
    if debug then ngx.log(ngx.ERR, "IP in static white list: "..ip) end
    return true
  end
  return false
end

function is_black()
  if ip_black:get(ip) then
    if debug  then ngx.log(ngx.ERR, "IP in automatic black list: "..ip) end
    if not test_mode then return true end
  end
  if blacklist[ip] then
    if debug  then ngx.log(ngx.ERR, "IP in static black list: "..ip) end
    if not test_mode then return true end
  end
  return false
end

function counter(x)
  local y = ip_new:get(x)
  if nill == y
  then
    y = 0
    ip_new:set(x, y, ttl_new)
  else
    y = y + 1
    ip_new:set(x, y, ttl_new)
  end
  return y
end

function is_above_treshold()
  if counter(ip_host) == 0
  then
    if debug  then ngx.log(ngx.ERR, "Request to the new host from IP: "..ip_host) end
    if counter(ip_hour) > ban_treshhold
    then
      if debug  then ngx.log(ngx.ERR, "IP above theshold: "..ip_hour.." User agent: "..user_agent) end
      return true
    end
  end
  return false
end

if is_good_user_agent()         then ngx.exit(ngx.OK) end
if is_static_content()          then ngx.exit(ngx.OK) end
if is_white()                   then ngx.exit(ngx.OK) end
if is_black() and not test_mode then ngx.exit(403) end

if is_above_treshold()
then
  ngx.log(ngx.ERR, "BAN IP: "..ip)
  ip_black:set(ip, 1, ttl_black)
end

ngx.exit(ngx.OK)
