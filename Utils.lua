-- MailOpener Utils.lua
-- Wrapper functions to handle bag/container API across versions

local function MO_GetNumFreeSlots(bagID)
    if C_Container and C_Container.GetContainerNumFreeSlots then
        return C_Container.GetContainerNumFreeSlots(bagID)
    else
        return GetContainerNumFreeSlots(bagID)
    end
end

local function MO_GetContainerNumSlots(bagID)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bagID)
    else
        return GetContainerNumSlots(bagID)
    end
end

local function MO_GetContainerItemInfo(bagID, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bagID, slot)
    else
        return GetContainerItemInfo(bagID, slot)
    end
end

local function MO_PickupContainerItem(bagID, slot)
    if C_Container and C_Container.PickupContainerItem then
        return C_Container.PickupContainerItem(bagID, slot)
    else
        return PickupContainerItem(bagID, slot)
    end
end

local function MO_SplitContainerItem(bagID, slot, amount)
    if C_Container and C_Container.SplitContainerItem then
        return C_Container.SplitContainerItem(bagID, slot, amount)
    else
        return SplitContainerItem(bagID, slot, amount)
    end
end

-- Expose globally
_G.MO_GetNumFreeSlots = MO_GetNumFreeSlots
_G.MO_GetContainerNumSlots = MO_GetContainerNumSlots
_G.MO_GetContainerItemInfo = MO_GetContainerItemInfo
_G.MO_PickupContainerItem = MO_PickupContainerItem
_G.MO_SplitContainerItem = MO_SplitContainerItem
