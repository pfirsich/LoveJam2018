local class = require("libs.class")

Counter = class("Counter")

function Counter:initialize(start)
    self.value = start or 0
end

function Counter:get()
    self.value = self.value + 1
    return self.value - 1
end

return Counter
