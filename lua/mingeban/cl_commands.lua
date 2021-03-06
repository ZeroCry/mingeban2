
local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

function mingeban.ConsoleAutoComplete(_, args)
	local autoComplete = {}

	local cmd = args:Split(" ")[2]
	local argsTbl = mingeban.utils.parseArgs(args)
	table.remove(argsTbl, 1)

	local argsStr = args:sub(cmd:len() + 2):Trim()
	local cmdData
	if cmd then
		cmdData = mingeban.GetCommand(cmd)
		if cmdData then
			local curArg = argsTbl[#argsTbl]
			local argData = cmdData.args[#argsTbl]
			if argData and argData.type == ARGTYPE_PLAYER then
				for _, ply in next, player.GetAll() do
					if ('"' .. ply:Nick() .. '"'):lower():match(curArg) then
						autoComplete[#autoComplete + 1] = '"' .. ply:Nick() .. '"' -- autocomplete nick
					end
				end
			end
		else
			for cmdName, cmdData in next, mingeban.commands do
				if type(cmdName) == "table" then
					for _, cmdName in next, cmdName do
						if cmdName:lower():match(cmd) then
							autoComplete[#autoComplete + 1] = cmdName -- autocomplete command
						end
					end
				elseif cmdName:lower():match(cmd) then
					autoComplete[#autoComplete + 1] = cmdName -- autocomplete command
				end
			end
		end
	end

	for k, v in next, autoComplete do -- adapt for console use
		local curArg = argsTbl[#argsTbl] or ""
		local argsStr = argsStr:sub(1, argsStr:len() - curArg:len(), 0):Trim()
		autoComplete[k] = "mingeban" .. (cmdData and (" " .. cmd .. " ") or "") .. argsStr .. " " .. v
	end

	if table.Count(autoComplete) <= 0 then -- no suggestions? print syntax
		autoComplete[1] = cmdData and "mingeban " .. (cmd or "") .. ((" " .. mingeban.GetCommandSyntax(cmd)) or "")
	end

	return autoComplete
end

net.Receive("mingeban_getcommands", function()
	local commands = net.ReadTable()

	for name, cmd in next, commands do
		for k, arg in next, cmd.args do
			cmd.args[k] = setmetatable(arg, Argument)
		end
		commands[name] = setmetatable(cmd, Command)
	end

	mingeban.commands = commands
end)

concommand.Add("mingeban", function(ply, _, cmd, args)
	local cmd = cmd[1]
	if not cmd then return end

	local args = args:Split(" ")
	table.remove(args, 1)
	args = table.concat(args, " ")
	-- local args = args:sub(cmd:len() + 2):Trim()

	net.Start("mingeban_runcommand")
		net.WriteString(cmd)
		net.WriteString(args)
	net.SendToServer()

end, mingeban.ConsoleAutoComplete)

for _, file in next, (file.Find("mingeban/commands/*.lua", "LUA")) do
	include("mingeban/commands/" .. file)
end

net.Receive("mingeban_cmderror", function()
	local reason
	local succ = pcall(function()
		reason = net.ReadString()
	end)

	surface.PlaySound("buttons/combine_button" .. table.Random({2, 3, 5, 7}) .. ".wav")
	if not reason or reason == "" then return end

	notification.AddLegacy("mingeban: " .. reason, NOTIFY_ERROR, 6)
end)

