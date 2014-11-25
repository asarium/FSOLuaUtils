local module = {}

local threads = {}

function module.secondsPassed(sec)
	local now = mn.getMissionTime()
	
	return function()
		local diff = mn.getMissionTime() - now
		return diff >= sec
	end
end

function module.waitUntil(func)
	while not func() do
		coroutine.yield()
	end
end

function module.startCoroutine(func)
	if type(func) ~= "function" then
		ba.error("startCoroutine called with non-function argument!")
		return nil
	end
	
	local co = coroutine.create(func)
	table.insert(threads, co)
	
	return co
end

function module.dispatcher()
	-- Iterate from the back so we can remove values safely
	for i=#threads,1,-1 do
		local thread = threads[i]
		local status, err = coroutine.resume(threads[i])
		
		if status and coroutine.status(thread) == "dead" then
			-- Thread is done
			table.remove(threads, i)
		elseif not status then
			-- Thread caused an error
			table.remove(threads, i)
			
			ba.error("Error in coroutine:\n" .. tostring(err))
		end
	end
end

return module