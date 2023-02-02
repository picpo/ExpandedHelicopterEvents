--for targeting
local bodyPartSelectionWeight = {
    ["Hand_L"]=5,["Hand_R"]=5,["ForeArm_L"]=10,["ForeArm_R"]=10,
    ["UpperArm_L"]=15,["UpperArm_R"]=15,["Torso_Upper"]=15,["Torso_Lower"]=15,
    ["Head"]=1,["Neck"]=1,["Groin"]=2,["UpperLeg_L"]=15,["UpperLeg_R"]=15,
    ["LowerLeg_L"]=10,["LowerLeg_R"]=10,["Foot_L"]=5,["Foot_R"]=5
}
local bodyPartSelection = {}
for type,weight in pairs(bodyPartSelectionWeight) do
    for i=1, weight do
        --print("body parts: "..i.." - "..type)
        table.insert(bodyPartSelection,type)
    end
end


local function squareGetZombieByID(square, ID)
    if not square then return end

    local movingObjects = square:getMovingObjects()
    if not movingObjects then return end

    for i=0, movingObjects:size()-1 do
        ---@type IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
        local zombie = movingObjects:get(i)
        if instanceof(zombie, "IsoZombie") and zombie:getOnlineID()==ID then
            return zombie
        end
    end
end


function heliEventAttackHitOnIsoGameCharacter(damage, targetType, targetID, x, y, z)

    if isServer() then
        sendServerCommand("helicopterEvent", "attack", {damage=damage, targetType=targetType, targetID=targetID, coords={x=x,y=y,z=z}})
        return
    end

    local square = getSquare(x, y, z)
    if not square then return end

    local targetHostile

    if targetType=="IsoZombie" and targetID then
        targetHostile = squareGetZombieByID(square, targetID)
    elseif targetType=="IsoPlayer" then
        targetHostile = getPlayerByOnlineID(targetID)
    end

    if not targetHostile and getDebug() then print("ERROR: event failed to find targetHostile to process attack hit.") return end

    local bpRandSelect = bodyPartSelection[ZombRand(#bodyPartSelection)+1]
    local bpType = BodyPartType.FromString(bpRandSelect)
    local clothingBP = BloodBodyPartType.FromString(bpRandSelect)

    --[[DEBUG]] local preHealth = targetHostile:getHealth()
    --apply damage to body part

    if (bpType == BodyPartType.Neck) or (bpType == BodyPartType.Head) then
        damage = damage*4
    elseif (bpType == BodyPartType.Torso_Upper) then
        damage = damage*2
    end

    if instanceof(targetHostile, "IsoZombie") then
        --Zombies receive damage directly because they don't have body parts or clothing protection
        damage = damage*3
        targetHostile:knockDown(true)

    elseif instanceof(targetHostile, "IsoPlayer") then
        --Messy process just to knock down the player effectively
        targetHostile:clearVariable("BumpFallType")
        targetHostile:setBumpType("stagger")
        targetHostile:setBumpDone(false)
        targetHostile:setBumpFall(ZombRand(0, 101) <= 25)
        local bumpFallType = {"pushedBehind","pushedFront"}
        bumpFallType = bumpFallType[ZombRand(1,3)]
        targetHostile:setBumpFallType(bumpFallType)

        --apply localized body part damage
        local bodyDMG = targetHostile:getBodyDamage()
        if bodyDMG then
            local bodyPart = bodyDMG:getBodyPart(bpType)
            if bodyPart then
                local protection = targetHostile:getBodyPartClothingDefense(BodyPartType.ToIndex(bpType), false, true)/100
                damage = damage * (1-(protection*0.75))
                --print("  EHE:[hit-dampened]: new damage:"..damage.." protection:"..protection)

                bodyDMG:AddDamage(bpType,damage)
                bodyPart:damageFromFirearm(damage)
            end
        end
    end

    targetHostile:addHole(clothingBP)
    targetHostile:addBlood(clothingBP, true, true, true)
    targetHostile:setHealth(targetHostile:getHealth()-(damage/100))

    --splatter a few times
    local splatIterations = ZombRand(1,3)
    for _=1, splatIterations do
        targetHostile:splatBloodFloor()
    end
end