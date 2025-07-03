local function isIdent(str)
    return string.match(str, "^[%a_][%w_]*$") ~= nil and not ({
        	["and"] = true,
    		["break"] = true,
    		["do"] = true,
    		["else"] = true,
    		["elseif"] = true,
    		["end"] = true,
    		["false"] = true,
    		["for"] = true,
    		["function"] = true,
    		["if"] = true,
    		["in"] = true,
    		["local"] = true,
    		["nil"] = true,
    		["not"] = true,
    		["or"] = true,
    		["repeat"] = true,
    		["return"] = true,
    		["then"] = true,
    		["true"] = true,
    		["until"] = true,
    		["while"] = true
        })[str]
end

function tstr(tbl, seen, indent)
	if type(tbl) == "string" then
		return ("%q"):format(tbl)
	end
	if type(tbl) ~= "table" or (
		getmetatable(tbl) and
		type(getmetatable(tbl)) == "table" and
		getmetatable(tbl).__tostring
	) then return tostring(tbl) end
	seen = seen or {}
	if seen[tbl] then return "..." end
	seen[tbl] = true
	indent = indent or 1
	local printed = false
	local strings = { "{" }
	local newLine = "\n" .. ("\t"):rep(indent)
	for i, value in ipairs(tbl) do
		printed = true
		table.insert(strings, newLine)
		table.insert(strings, tstr(value, seen, indent + 1))
		table.insert(strings, ", ")
	end
	for key, value in pairs(tbl) do
		if not (type(key) == "number" and key <= #tbl) then
			printed = true
			table.insert(strings, newLine)
			if type(key) == "string" and isIdent(key) then
				table.insert(strings, ("%s = "):format(key))
			else
				table.insert(strings, ("[%s] = "):format(tstr(key, seen, indent + 1)))
			end
			if type(value) == "string" then
				table.insert(strings, ("%q"):format(value))
			else
				table.insert(strings, ("%s"):format(tstr(value, seen, indent + 1)))
			end
			table.insert(strings, ", ")
		end
	end

	if printed then
		strings[#strings] = "\n" .. ("\t"):rep(indent - 1)
	end

	return table.concat(strings, "") .. "}"
end

function tprint(tbl)
	print(tstr(tbl))
end
