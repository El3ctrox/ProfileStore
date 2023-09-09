local function match(data, pattern: { [any]: any })
    
    if typeof(pattern) == "table" then
        
        if typeof(data) ~= "table" then return false end
        
        for index, patternValue in pattern do
            
            if not match(data[index], patternValue) then return false end
        end
        
        for index in data do
            
            if pattern[index] == nil then return false end
        end
        
        return true
        
    elseif typeof(pattern) == "string" then
        
        return typeof(data) == "string" and pattern:match(data)
    else
        
        return data == pattern
    end
end

return function()
    
    local DataLoader = require(script.Parent)
    
    describe("Color3 data loader", function()
        
        local colorLoader = DataLoader.color()
            :enableCorrection()
        
        it("should load RGB(2, 3, 4)", function()
            
            local data = { R = 2, G = 3, B = 4 }
            local color = colorLoader:load(data)
            
            expect(typeof(color)).to.be.equal("Color3")
            expect(color.R*255).to.be.near(data.R, .1)
            expect(color.G*255).to.be.near(data.G, .1)
            expect(color.B*255).to.be.near(data.B, .1)
        end)
        it("should fill missing fields", function()
            
            local data = { R = 50, G = 255 }
            local color = colorLoader:load(data)
            
            expect(typeof(color)).to.be.equal("Color3")
            expect(color.B).to.be.equal(0)
            expect(data.B).to.be.equal(0)
        end)
        it("should convert missing fields", function()
            
            local data = { R = "255", G = 50, B = 10 }
            local color = colorLoader:load(data)
            
            expect(typeof(color)).to.be.equal("Color3")
            expect(color.R*255).to.be.near(255, .1)
            expect(color.G*255).to.be.near(50, .1)
            expect(color.B*255).to.be.near(10, .1)
            
            expect(data.R).to.be.equal(255)
        end)
        it("should discart without default data", function()
            
            local color = colorLoader:load(nil)
            expect(color).to.be.equal(nil)
        end)
    end)
    
    describe("array data loader", function()
        
        local itemsLoader = DataLoader.array(DataLoader.string())
        
        it("should load all elements", function()
            
            local data = { "sword", "apple" }
            local items = itemsLoader:load(data)
            
            expect(match(items, { "sword", "apple" })).to.be.ok()
        end)
        it("should discart bad elements", function()
            
            local data = { "armor", 5, "cavalo" }
            local items = itemsLoader:load(data)
            
            expect(match(items, { "armor", "cavalo" })).to.be.ok()
        end)
    end)
    
    describe("set data loader", function()
        
        local setLoader = DataLoader.set(
            DataLoader.integer(),
            DataLoader.string()
        )
        
        it("should load data", function()
            
            local data = {
                { index = 1, value = "sword" },
                { index = 3, value = "apple" },
                { index = 10, value = "armor" },
            }
            local inventory = setLoader:load(data)
            
            expect(match(inventory, {
                [1] = "sword",
                [3] = "apple",
                [10] = "armor"
            }))
        end)
        it("should discart bad indexes", function()
            
            local data = {
                { index = 1, value = "sword" },
                { index = "maxItems", value = 5 },
                { index = 10, value = "armor" },
            }
            local inventory = setLoader:load(data)
            
            expect(match(inventory, {
                [1] = "sword",
                [10] = "armor"
            }))
        end)
    end)
    
    describe("struct data loader", function()
        
        local itemLoader = DataLoader.struct{
            name = DataLoader.string():enablePanic(),
            level = DataLoader.integer(1),
            color = DataLoader.color(Color3.new())
        }:enableCorrection()
        
        it("should load all fields", function()
            
            local data = { name = "sword", level = 2, color = { R = 0, G = 255, B = 50 } }
            local item = itemLoader:load(data)
            
            expect(match(item, { name = "sword", level = 2, color = Color3.fromRGB(0, 255, 50) }))
        end)
        it("should fill missing fields", function()
            
            local data = { name = "sword", level = 1 }
            local item = itemLoader:load(data)
            
            expect(match(item, { name = "sword", level = 1, color = Color3.new() }))
        end)
        it("should discart when miss main field", function()
            
            local data = { level = 3 }
            local item = itemLoader:load(data)
            
            print(itemLoader:check(data))
            
            expect(item).to.be.equal(nil)
        end)
    end)
end