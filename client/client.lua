local player = GetPlayerPed(-1)
local vehicle
local actualFuelAmount
local fullTank = 100
local canPay = false
local running = false
local gasPrice = 1.85

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedInAnyVehicle(player, true) then
            vehicle = GetVehiclePedIsIn(player, true)
        end
        if vehicle ~= nil then
            local vehCoords = GetEntityCoords(vehicle)
            local pedCoords = GetEntityCoords(player)
            vehicle = GetVehiclePedIsIn(player, true)
            actualFuelAmount = GetVehicleFuelLevel(vehicle)

            if getCoordsDistance() then
                showMenu()
                if IsControlJustPressed(0, 38) then
                    if IsPedInAnyVehicle(player, false) then
                        ESX.ShowNotification("You must be out of the car to fill the tank")    
                    elseif compareDistances(pedCoords, vehCoords, false) < 5 then
                        TriggerEvent('GasStation:ui-on')
                    else
                        ESX.ShowNotification("You are far from your vehicle")
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('GasStation:ui-on', function()

    ESX.TriggerServerCallback('GasStation:GetInformation', function(gasPrice, tankDamage, amountMax) 
        if(tankDamage < 20 ) then 
            tankDamage = "Tank Fuel danificado! Aconselha-se a reparação!"
        end
        if GetVehicleFuelLevel(vehicle) >= 99 then
            ESX.ShowNotification("Your car is already with its tank full!")
            return
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "ui",
            visible = true,
            gasPrice = gasPrice,
            tankDamage = tankDamage,
            amountMax = amountMax
        })
    end, actualFuelAmount)
end)

RegisterNUICallback('GasStation:ui-off', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "ui",
        visible = false
    })
end)

RegisterNUICallback('GasStation:fuel', function(data)

    local quantity = data.amount
    if quantity == "" then
        quantity = 0
        ESX.ShowNotification("Seleciona o valor que queres atestar")
        return
    end
    local finalactualFuelAmount = actualFuelAmount + (quantity*1)/gasPrice

    if payGas(quantity) then
        SetVehicleFuelLevel(vehicle, finalactualFuelAmount)
        ESX.ShowNotification("Your car is now with " .. string.format("%.0f", GetVehicleFuelLevel(vehicle)) .. "% of fuel")
    end
end)

RegisterNUICallback('GasStation:fuelfull', function(data)
    local quantity = (100 - actualFuelAmount) * 1 / gasPrice
    if payGas(quantity) then
        SetVehicleFuelLevel(vehicle, fullTank)
        ESX.ShowNotification("Your car is now with " .. string.format("%.0f", GetVehicleFuelLevel(vehicle)) .. "% of fuel")
    end
end)

function payGas(amount)
    running = true
    
    TriggerServerEvent('GasStation:PayGasSV', amount)
    while running do
        Wait(200)
    end
    print(canPay)
    if canPay then
        return true
    end

    ESX.ShowNotification("Sorry! We just take cash and it looks like u dont hav it!")
    return false
end

RegisterNetEvent('GasStation:PayGas', function(bool)
    canPay = bool
    running = false
end)

function getCoordsDistance()
    local playerCoords = GetEntityCoords(player)
    local gasStations = Config.GasStations
    
    for j=1, #gasStations.stations, 1 do
        for k=1, #gasStations.stations[j].Poles, 1 do
            if compareDistances(playerCoords, gasStations.stations[j].Poles[k], false) < 1.8 then
                return true
            end
        end
    end

    return false
end

function compareDistances(obj1, obj2, considerZ)
    return GetDistanceBetweenCoords(obj1.x, obj1.y, obj1.z, obj2.x, obj2.y, obj2.z, considerZ)
end

function showMenu()
    SetTextScale(0.6, 0.6)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(false)
    AddTextComponentString('Press E to fuel')
    DrawText(0.825, 0.825)    
end