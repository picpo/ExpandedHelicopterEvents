---FLARE SYSTEM PROPER
local eheFlareSystem = {}
eheFlareSystem.activeObjects = {}
eheFlareSystem.activeTimes = {}
eheFlareSystem.activeLightSources = {}
eheFlareSystem.activeSoundLoop = {}
eheFlareSystem.Duration = 30
eheFlareSystem.flareTypes = {} --["HandFlare"] = "EHEFlare", ["SignalFlare"] = "EHESignalFlare", }

function eheFlareSystem.getFlareTypes() return eheFlareSystem.flareTypes end

function eheFlareSystem.addFlareType(itemModuleDotType, flareType)
    if not itemModuleDotType or not flareType then return end
    eheFlareSystem.flareTypes[itemModuleDotType] = flareType
end

---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.getFlareWhereContained(flareObject)
    if flareObject and instanceof(flareObject, "InventoryItem") then
        local containing = flareObject:getOutermostContainer()
        if containing then return containing:getParent() end

        ---@type IsoWorldInventoryObject|IsoObject
        local worldItem = flareObject:getWorldItem()
        if worldItem then return worldItem end

        if isServer() then sendServerCommand("flare", "updateLocation", {flare=flareObject}) end

        local sentLoc = eheFlareSystem.activeObjects[flareObject]
        if sentLoc then return getSquare(sentLoc.x,sentLoc.y,sentLoc.z) end
    end
end



---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.getFlareOuterMostSquare(flareObject)
    local containedIn = eheFlareSystem.getFlareWhereContained(flareObject)
    if containedIn then
        if instanceof(containedIn, "IsoGridSquare") then return containedIn end
        return containedIn:getSquare()
    end
end


---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.activateFlare(flareObject, duration, location)

    if isClient() then
        local flareSquare = eheFlareSystem.getFlareOuterMostSquare(flareObject)
        local fSquareXYZ = {x=flareSquare:getX(),y=flareSquare:getY(),z=flareSquare:getZ()}
        sendClientCommand("flare","activate", {flare=flareObject, duration=duration, loc=fSquareXYZ})
    else
        print("flareObject:"..tostring(flareObject).."   duration:"..duration)

        if not flareObject or not duration or (duration and duration<=0) then return end

        eheFlareSystem.activeObjects[flareObject] = location
        eheFlareSystem.activeTimes[flareObject] = getGameTime():getMinutesStamp()+duration

        triggerEvent("EHE_OnActivateFlare", flareObject)
    end
end


function eheFlareSystem.processLightSource(flare, x, y, z, active)

    if isServer() then
        sendServerCommand("flare", "processLightSource", {flare=flare, x=x, y=y, z=z, active=active})

    else
        ---@type IsoLightSource|IsoLightSource
        local currentLightSource = eheFlareSystem.activeLightSources[flare]

        if active==true then
            eheFlareSystem.activeLightSources[flare] = IsoLightSource.new(x, y, z, 200, 0, 0, 4)
            getCell():addLamppost(eheFlareSystem.activeLightSources[flare])
        end

        if currentLightSource then
            currentLightSource:setActive(false)
            getCell():removeLamppost(currentLightSource)
        end

        if active==false then
            flare:setCondition(0)
            flare:setName(getText("IGUI_Spent").." "..flare:getScriptItem():getDisplayName())
        end
    end
end

function eheFlareSystem.sendDuration(flare, timestamp)
    if (not isClient()) or (not flare) or (not timestamp) then return end
    flare:getModData()["flareDuration"] = timestamp
end

function eheFlareSystem.validateFlare(flare, timestamp)

    --print(" -- flare:"..tostring(flare~=nil).."  "..timestamp.."  "..getGameTime():getMinutesStamp())

    if timestamp > getGameTime():getMinutesStamp() then
        print(" -- -- flare ts > gTgMS  server:"..tostring(isServer()))
        flare:getModData()["flareDuration"] = (timestamp-getGameTime():getMinutesStamp())
        if isServer() then sendServerCommand("flare", "sendDuration", {flare=flare, duration=flare:getModData()["flareDuration"]}) end

        ---@type IsoGridSquare
        local flareSquare = eheFlareSystem.getFlareOuterMostSquare(flare)
        if flareSquare then
            local fsqX, fsqY, fsqZ = flareSquare:getX(), flareSquare:getY(), flareSquare:getZ()
            print(" -- -- -- SQUARE")
            eheFlareSystem.processLightSource(flare, fsqX, fsqY, fsqZ, true)
            addSound(nil, flareSquare:getX(),flareSquare:getY(), flareSquare:getZ(), 15, 25)

            if not eheFlareSystem.activeSoundLoop[flare] or eheFlareSystem.activeSoundLoop[flare] < getTimeInMillis() then
                eheFlareSystem.activeSoundLoop[flare] = getTimeInMillis()+750

                if isServer() then
                    sendServerCommand("sound", "play", {soundEffect="eheFlare", coords={x=fsqX,y=fsqY,z=fsqZ}})
                else
                    flareSquare:playSound("eheFlare")
                end
            end
        end

    else
        eheFlareSystem.activeObjects[flare] = nil
        eheFlareSystem.activeTimes[flare] = nil
        flare:getModData()["flareDuration"] = 0
        if isServer() then sendServerCommand("flare", "sendDuration", {flare=flare, duration=0}) end
        eheFlareSystem.processLightSource(flare, nil, nil, nil, false)
    end
end


function eheFlareSystem.validateFlares()
    for flareObject,timestamp in pairs(eheFlareSystem.activeTimes) do eheFlareSystem.validateFlare(flareObject, timestamp) end
end
if not isClient() then
    Events.OnTick.Add(eheFlareSystem.validateFlares)
end


eheFlareSystem.scannedObjects = {}
---@param object IsoPlayer|IsoObject|IsoGridSquare|IsoGameCharacter
function eheFlareSystem.scanForActiveFlares(object)
    if not object then return end

    if eheFlareSystem.scannedObjects[object] then return end
    eheFlareSystem.scannedObjects[object] = true

    local items

    if instanceof(object, "IsoGameCharacter") then
        items = object:getInventory():getItems()
    elseif instanceof(object, "IsoGridSquare") then
        items = object:getWorldObjects()
    end

    if items and items:size()>0 then
        for iteration=0, items:size()-1 do
            local item = items:get(iteration)

            if item and instanceof(item, "IsoWorldInventoryObject") then item = item:getItem() end

            if item and instanceof(item, "InventoryItem") then
                local flareDuration = item:getModData()["flareDuration"]
                local flareType = eheFlareSystem.flareTypes[item:getFullType()]
                if item and flareType and (flareType =="EHEFlare") and (not item:isBroken()) and flareDuration and flareDuration>0 then
                    --print(" -- found previously active flare: "..tostring(object).."  durationLeft: "..flareDuration)
                    eheFlareSystem.activateFlare(item, flareDuration)
                end
            end
        end
    end
end
Events.OnPlayerUpdate.Add(eheFlareSystem.scanForActiveFlares)
Events.LoadGridsquare.Add(eheFlareSystem.scanForActiveFlares)



LuaEventManager.AddEvent("EHE_OnActivateFlare")

---RECIPE STUFF
EHE_Recipe = EHE_Recipe or {}

---@param player IsoGameCharacter|IsoPlayer|IsoMovingObject
---@param result InventoryItem|IsoObject
function EHE_Recipe.onFlareLight(recipe, result, player)
    local flare

    for i=0, recipe:size()-1 do
        ---@type InventoryItem
        local item = recipe:get(i)
        if eheFlareSystem.getFlareTypes()[item:getFullType()]=="EHEFlare" then
            flare = item
            item:setName(getText("IGUI_Lit").." "..item:getScriptItem():getDisplayName())
        elseif eheFlareSystem.flareTypes[item:getFullType()]=="EHESignalFlare" then
            item:setCondition(0)
            item:setName(getText("IGUI_Spent").." "..item:getScriptItem():getDisplayName())
            if not player:isOutside() then
                local pSquare = player:getSquare()
                IsoFireManager.StartFire(getCell(), pSquare, true, 5, 20)
            end
        end
    end

    if eheFlareSystem.getFlareTypes()[result:getFullType()]=="EHEFlare" then
        flare = flare or result
        if result==flare then
            player:getInventory():DoRemoveItem(result)
            player:getSquare():AddWorldInventoryItem(result, 0, 0, 0)
            result:getWorldItem():transmitCompleteItemToServer()
        end
    end
    eheFlareSystem.activateFlare(flare, eheFlareSystem.Duration)
end


---@param player IsoGameCharacter | IsoPlayer
---@param item InventoryItem
function EHE_Recipe.onCanLightFlare(recipe, player, item)
    --and (not eheFlareSystem.activeObjects[item])
    if item and (not item:isBroken()) and (not item:getModData()["flareDuration"]) then
        return true
    end
    return false
end


return eheFlareSystem