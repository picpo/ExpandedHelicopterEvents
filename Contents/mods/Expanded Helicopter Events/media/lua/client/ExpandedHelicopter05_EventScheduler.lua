function eHeliEvent_new(replacePos, startDay, startTime, endTime, renew)

	if (not startDay) or (not startTime) or (not endTime) then
		return
	end

	local o = {["startDay"] = startDay, ["startTime"] = startTime, ["endTime"] = endTime, ["renew"] = renew, ["triggered"] = false}

	if replacePos then
		getGameTime():getModData()["EventsSchedule"][replacePos] = o
	else
		table.insert(getGameTime():getModData()["EventsSchedule"], o)
	end
end


function eHeliEvent_weatherImpact()
	local CM = getClimateManager()
	local willFly = true
	local impactOnFlightSafety = 0
	local wind = CM:getWindIntensity()
	local fog = CM:getFogIntensity()
	local rain = CM:getRainIntensity()/2
	local snow = CM:getSnowIntensity()/2
	local thunder = CM:getIsThunderStorming()

	if (wind+rain+snow > 0.90) or (fog > 0.33) or (thunder == true) then
		willFly = false
	end

	impactOnFlightSafety = (wind+rain+snow+(fog*3))/6

	return willFly, impactOnFlightSafety
end


function eHeliEvent_engage(ID)
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local eHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]
	eHeliEvent.triggered = true

	local willFly,_ = eHeliEvent_weatherImpact()

	if willFly then
		getFreeHelicopter():launch()
	end

	if eHeliEvent.renew then
		setNextHeliFrom(ID)
	end
end


eHeliEvent_cutOffDay = 30
function setNextHeliFrom(ID, heliDay, heliStart, heliEnd)

	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local lastHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]

	if not heliDay then
		if lastHeliEvent then
			heliDay = lastHeliEvent.startDay
		else
			heliDay = getGameTime():getNightsSurvived()
		end
		-- options = Never=0, Once=1, Sometimes=2, Often=3
		if eHelicopterSandbox.config.frequency <= 2 then
			heliDay = heliDay+ZombRand(4, 7)
			-- if frequency is 3 / often
		elseif eHelicopterSandbox.config.frequency == 3 then
			heliDay = heliDay+ZombRand(1, 3)
		end
	end

	if not heliStart then
		--start time is random from hour 9 to 19
		heliStart = ZombRand(9, 19)
	end

	if not heliEnd then
		--end time is start time + 1 to 5 hours
		heliEnd = heliStart+ZombRand(1,5)
	end

	local renewHeli = true
	if (eHelicopterSandbox.config.frequency == 1) or (eHeli_getDaysBeforeApoc+heliDay > eHeliEvent_cutOffDay) then
		renewHeli = false
	end

	eHeliEvent_new(ID, heliDay, heliStart, heliEnd, renewHeli)
end


---Check how many days it has been since the start of the apocalypse
function eHeli_getDaysBeforeApoc()

	local monthsAfterApo = getSandboxOptions():getTimeSinceApo()-1
	--no months to count, go away
	if monthsAfterApo <= 0 then
		return 0
	end

	local gameTime = getGameTime()
	local startYear = gameTime:getStartYear()
	--months of the year start at 0
	local apocStartMonth = (gameTime:getStartMonth()+1)-monthsAfterApo
	--roll the year back
	if apocStartMonth <= 0 then
		apocStartMonth = 12+apocStartMonth
		startYear = startYear-1
	end
	--days of the month start at 0
	local apocDays = gameTime:getStartDay()+1
	--count each month at a time to get correct day count
	for _=1, monthsAfterApo do
		apocStartMonth = apocStartMonth+1
		--roll year forward if needed, reset month
		if apocStartMonth > 12 then
			apocStartMonth = 1
			startYear = startYear+1
		end
		--months of the year start at 0
		local daysInM = gameTime:daysInMonth(startYear, apocStartMonth-1)
		apocDays = apocDays+daysInM
	end

	return apocDays
end


function eHeliEvents_OnGameStart()

	--if no ModData found make it an empty list
	if not getGameTime():getModData()["EventsSchedule"] then
		getGameTime():getModData()["EventsSchedule"] = {}
	end

	--if eHelicopterSandbox.config.resetEvents == true, reset
	if eHelicopterSandbox.config.resetEvents == true then
		getGameTime():getModData()["EventsSchedule"] = {}
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.configMenu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end

	--if the list is empty call new heli event
	if #getGameTime():getModData()["EventsSchedule"] < 1 then
		setNextHeliFrom(nil, getGameTime():getNightsSurvived())
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)


function eHeliEvent_Loop()
	local DAY = getGameTime():getNightsSurvived()
	local HOUR = getGameTime():getHour()

	for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
		if (not v.triggered) and (v.startDay <= DAY) and (v.startTime >= HOUR) then
			eHeliEvent_engage(k)
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)