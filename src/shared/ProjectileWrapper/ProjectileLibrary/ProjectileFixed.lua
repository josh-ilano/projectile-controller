--!strict
local Projectile = {}
Projectile.__index = Projectile




export type Projectile = 
	{	
		_projectileChoice: string,
		_controlPoints: {Vector3},
		_waypoints: {Vector3},
	}



local Linear = function(t: number, A: Vector3, B: Vector3): Vector3
	return A + (B - A) * t
end


local CubicBezier = function(t: number, p0: number, p1: number, p2: number, p3: number)
	return (1 - t) ^ 3 * p0 + 3 * (1 - t) ^ 2 * t * p1 + 3 * (1 - t) * t ^ 2 * p2 + t ^ 3 * p3
end


local QuadraticBezier = function(t: number, p0: Vector3, p1: Vector3, p2: Vector3): Vector3	
	local u = 1 - t
	return
		(u * u) * p0 +
		(2 * u * t) * p1 +
		(t * t) * p2
end

local funLibrary = 
	{
	Linear = function(...) return Linear(...) end,
	Quad = function(...) return QuadraticBezier(...) end,
	Cubic = function(...) return CubicBezier(...) end
}




local function generateBezierPoints(segments, trajectoryChoice, ...) -- the '...' are control points!
	local points = {}

	for i = 0, segments do
		local t = i / segments
		local waypoint = funLibrary[trajectoryChoice](t, ...)
		table.insert(points, waypoint)
	end
	return points
end


function Projectile.ReturnMidpoint(startPoint: Vector3, endPoint: Vector3)
	return (startPoint + endPoint) / 2
end


function Projectile.new(projectileChoice: string, controlPoints: {Vector3}, numWaypoints: number): Projectile
	local self: Projectile = setmetatable({
		_projectileChoice = projectileChoice,
		_controlPoints  = controlPoints,
		_waypoints = generateBezierPoints(numWaypoints, projectileChoice, table.unpack(controlPoints))
		
	}, Projectile) :: Projectile

	return self
end



function Projectile:Visualize(
	parent: Instance?,
	size: Vector3?,
	color: Color3?
)
	parent = parent or workspace
	size = size or Vector3.new(0.5, 0.5, 0.5)
	color = color or Color3.fromRGB(0, 255, 0)

	for _, pos in ipairs(self._waypoints) do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Size = size
		part.Color = color
		part.Position = pos
		part.Parent = parent
	end
end


return Projectile
