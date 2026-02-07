-- Quick test for Scene class
local Scene = require('src.core.scene')

-- Test 1: Scene instance creation
local scene = Scene:new()
assert(scene ~= nil, "Scene instance should be created")
print("✓ Scene:new() creates instance")

-- Test 2: All methods can be called without errors
scene:enter({test = "params"})
print("✓ enter() callable")

scene:exit()
print("✓ exit() callable")

scene:update(0.016)
print("✓ update() callable")

scene:draw()
print("✓ draw() callable")

scene:keypressed('space')
print("✓ keypressed() callable")

scene:mousepressed(100, 200, 1)
print("✓ mousepressed() callable")

print("\n✅ All tests passed - Scene base class working correctly")
