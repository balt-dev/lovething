local inifile = {}

---@param data string
---@return table
function inifile.parse(data)
	local t = {}
	local section
	for line in data:gmatch("[^\r\n]+") do
		local s = line:match("^%[([^%]]+)%]$")
		if s then
			section = s
			t[section] = t[section] or {}
		end
		local key, value = line:match("^(%w+)%s*=%s*(.+)$")
		if key and value then
			if tonumber(value) then value = tonumber(value) end
			if value == "true" then value = true end
			if value == "false" then value = false end
			if section then
				t[section][key] = value
			else
				t[key] = value
			end
		end
	end
	return t
end

---@param tbl table
---@return string
function inifile.dump(tbl)
	local contents = {}
	for section, s in pairs(tbl) do
		table.insert(contents, ("[%s]\n"):format(section))
		for key, value in pairs(s) do
			table.insert(contents, ("%s = %s\n"):format(key, tstr(value)))
		end
		table.insert(contents, "\n")
	end
	return table.concat(contents)
end

return inifile
