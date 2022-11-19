local whitelist_file='/etc/nginx/lua-aniddos/ddos_whitelist.txt'
local blacklist_file='/etc/nginx/lua-aniddos/ddos_blacklist.txt'

whitelist = {}
blacklist = {}

-- see if the file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty.
-- list/table if the file does not exist
local function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do
      if not string.match(line, '^#') then
--      lines[#lines + 1] = line
        lines[line] = 1
      end
  end
  return lines
end

whitelist = lines_from(whitelist_file)
blacklist = lines_from(blacklist_file)

