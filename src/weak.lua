--- Returns a weak reference to a table.
--- Accessing fields on this object may return nil.
return function(table)
	return setmetatable({__ref = table}, {
		__mode = "v",
		__index = function(t, k) return t.__ref and t.__ref[k] end,
		__newindex = function(t, k, v) if t.__ref then t.__ref[k] = v end end,
		__tostring = function(v) return "<weakref>" end
	})
end
