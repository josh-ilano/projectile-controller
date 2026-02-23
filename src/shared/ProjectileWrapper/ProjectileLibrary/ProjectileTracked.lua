local RunService = game:GetService('RunService')

local Projectile = {}
Projectile.__index = Projectile


export type Projectile = 
	{	
		_projectileChoice: string,
		_controlPoints: {Vector3},
		_numWaypoints: number,
		
		_start: Model | BasePart,
		_end: Model | BasePart,
		
		_staticStart: Vector3,
		_staticEnd: Vector3
	}

local Linear = function(t: number, p0: Vector3, p1: Vector3): Vector3
	return p0 + (p1 - p0) * t
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

local QuarticBezier = function(t, P0, P1, P2, P3, P4)
	local u = 1 - t
	local tt = t * t
	local uu = u * u
	local uuu = uu * u
	local ttt = tt * t

	return
		P0 * (uu * uu) +
		P1 * (4 * uuu * t) +
		P2 * (6 * uu * tt) +
		P3 * (4 * u * ttt) +
		P4 * (tt * tt)
end


-- THESE FUNCTIONS DESCRIBE HOW CONTROL POINTS SHOULD RESPOND TO THE MOVEMENT OF OUR TARGETS
local function moveQuarticBothEnds(deltaStart, deltaEnd, ...)
	local P0, P1, P2, P3, P4 = ...
	local w1 = 0.75 -- closer to start
	local w2 = 0.5  -- middle
	local w3 = 0.25 -- closer to end

	return {
		P0 + deltaStart,
		P1 + deltaStart * w1 + deltaEnd * (1 - w1),
		P2 + deltaStart * w2 + deltaEnd * (1 - w2),
		P3 + deltaStart * w3 + deltaEnd * (1 - w3),
		P4 + deltaEnd
	}
end


local function moveCubicBothEnds(deltaStart, deltaEnd, ...)
	local P0, P1, P2, P3 = ...
	local w = 0.5

	return
		{P0 + deltaStart,
		P1 + deltaStart * w + deltaEnd * (1 - w),
		P2 + deltaStart * (1 - w) + deltaEnd * w,
		P3 + deltaEnd}
end

local function moveQuadraticBothEnds(deltaStart, deltaEnd, ...)
	
	local P0, P1, P2 = ...
	local w = 0.5 
	
	return
		{P0 + deltaStart,
		P1 + deltaStart * (1 - w) + deltaEnd * w,
		P2 + deltaEnd}
end


local funLibrary = 
	{
	Linear = {Path = function(...) return Linear(...) end },
	Quad = {Path = function(...) return QuadraticBezier(...) end, BothEnds = function(...) return moveQuadraticBothEnds(...) end},
	Cubic = {Path = function(...) return CubicBezier(...) end, BothEnds = function(...) return moveCubicBothEnds(...) end},
	Quartic = {Path = function(...) return QuarticBezier(...) end, BothEnds = function(...) return moveQuarticBothEnds(...) end}
}


local function returnPosition(instance)
	if typeof(instance) == "Vector3" then return instance end
	
	if instance:IsA("Model") then
		return instance.PrimaryPart.Position
	elseif instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Attachment") then
		return instance.WorldPosition
	end
end


-- CONTROL POINTS ARE ONLY THE INTERMEDIARY POINTS

type target = Model | BasePart | Vector3 | Attachment
function Projectile.new(projectileChoice: string, controlPoints: {Vector3}, A: target, B: target, speed: number): Projectile
	
	local self: Projectile = setmetatable({
		_projectileChoice = projectileChoice,
		_controlPoints  = controlPoints,
		_speed = speed,
		
		_start = A,
		_end = B,
		
		
		_staticStart = returnPosition(A),
		_staticEnd = returnPosition(B),
	}, Projectile) :: Projectile

	
	table.insert(self._controlPoints, 1, self._staticStart)
	table.insert(self._controlPoints, self._staticEnd)
	-- add start and end to controlpoints

	return self
end




function Projectile:ReturnWaypoint(t)
	local wp 

	if self._projectileChoice == "Linear" then
		wp = funLibrary.Linear.Path(t, returnPosition(self._start), returnPosition(self._end))
	else -- FOR HIGHER-ORDER CURVES, WE RECOMPUTE CONTROL POINTS AND THEN REESTABLISH THE CURVATURE PATH
		-- deviations from start and end
		local dS = returnPosition(self._start) - self._staticStart 
		local dE = returnPosition(self._end) - self._staticEnd 

		local controlPoints = funLibrary[self._projectileChoice].BothEnds(
			dS, dE, table.unpack(self._controlPoints))
		
		-- return calculated point from newly generated control points
		wp = funLibrary[self._projectileChoice].Path(t, table.unpack(controlPoints))
	end
	
	return wp
end


function Projectile:VisualizeMotion(projectile, movementFunc)
	
	local studsToTravel = 0
	
	local conn
	local frame = 0
	local length = self:CalculateMagnitude(self._controlPoints, 2)

	
	local impactEvent = Instance.new("BindableEvent")
	
	conn = RunService.Heartbeat:Connect(function(deltaTime: number) 
		
		frame += 1
		if frame % 5 == 0 then
			if self._projectileChoice == "Linear" then
				length = (returnPosition(self._start) - returnPosition(self._end)).Magnitude
			else
				length = self:CalculateMagnitude(self._controlPoints, 2)
			end
		end
	
		
		-- t is a value from 0 to 1 
		studsToTravel += self._speed * deltaTime 

		local t = math.min(studsToTravel / length, 1)
		if t == 1 then conn:Disconnect(); impactEvent:Fire() end
	
		local wp: Vector3 = self:ReturnWaypoint(t)
		local future_wp: Vector3 = self:ReturnWaypoint(math.min(t+.01, 1))
		
		
		if movementFunc then movementFunc(projectile) end
		if wp == future_wp then projectile.CFrame = CFrame.new(wp) else projectile.CFrame = CFrame.new(wp, future_wp) end 
		-- EDGE CASE: when wp is the same as future_wp, then CFrane.lookAt will return a strange result 
		-- as the lookPosition is the same as the actual wp... therefore just using wp is adequate
	end)
	
	return impactEvent
	
end


-- CREATE A TRAIL OF PARTS WITH TRAILEN THAT FOLLOW THE SPECIFIED CURVE
function Projectile:VisualizeTrail(projectile, movementFunc, trailLen)
	
	local projectiles = {projectile} -- automatically add the head to the list
	for i=1, trailLen-1 do -- add the other projectiles
		local projectileClone = projectile:Clone()
		projectileClone.Parent = workspace.Effects
		table.insert(projectiles, projectileClone)
	end
	
	local studsToTravel = 0

	local conn
	local frame = 0
	local length = self:CalculateMagnitude(self._controlPoints, 2)

	local impactEvent = Instance.new("BindableEvent")
	local points = {}

	conn = RunService.Heartbeat:Connect(function(deltaTime: number) 

		frame += 1
		if frame % 5 == 0 then length = self:CalculateMagnitude(self._controlPoints, 2) end

		-- t is a value from 0 to 1 
		studsToTravel += self._speed * deltaTime 
		local t = math.min(studsToTravel / length, 1)
		if t == 1 then conn:Disconnect(); impactEvent:Fire() end

		

		local wp: Vector3 = self:ReturnWaypoint(math.clamp(t, 0, 1))

		table.insert(points, wp)
		-- EDGE CASE: when wp is the same as future_wp, then CFrane.lookAt will return a strange result 
		-- as the lookPosition is the same as the actual wp... therefore just using wp is adequate
			
		for i, projectile in projectiles do -- i=1 means that's the head, #projectile is the head
			if movementFunc then movementFunc(projectile, i) end
			
			local wp = points[math.max(1,#points-(i-1)*3)]
			local future_wp: Vector3 = self:ReturnWaypoint(math.clamp(t+.01, 0, 1))
			
			if wp == future_wp then projectile.CFrame = CFrame.new(wp) else projectile.CFrame = CFrame.new(wp, future_wp) end
		end

	end)

	return impactEvent, projectiles

end


-- de Casteljau's algorithm
-- input: The control points and t
function Projectile:CalculateMagnitude(controlPoints, j)
	
	local t = .5
	local controlDic = {}
	
	controlDic[0] = controlPoints 
	
	for level=1, #controlPoints-1 do
		local lastCp: Vector3
		local newPoints = {}
		for i, controlPoint: Vector3 in controlDic[level-1] do
			if i > 1 then
				table.insert(newPoints, lastCp:Lerp(controlPoint, t))
			end
			lastCp = controlPoint
		end
		controlDic[level] = newPoints
	end

	
	local leftCurvePoints = {} -- stores discrete curve generated by sampling points
	local rightCurvePoints = {}
	local lastWp 
	
	
	local totalMagnitude = 0
	local numPoints = 2*(#controlPoints-1)

	for i = 0, numPoints do
		local level, index, wp
		
		if i <= numPoints/2 then -- generating the left curve is from the first curve point to middle
			level, index = i, 1
			wp = controlDic[level][index]
			table.insert(leftCurvePoints, wp)
		end
		
		if i >= numPoints/2 then -- generating the right curve is from the middle to the final curve point
			level, index = numPoints - i, #controlDic[numPoints-i]
			wp = controlDic[level][index]
			table.insert(rightCurvePoints, wp)
		end

		if i > 0 then
			totalMagnitude += (wp-lastWp).Magnitude
		end
		
		lastWp = wp
	end
	

	if j > 0 then -- RECURSIVE CASE: DIVIDE THE CURVE INTO TWO SEPARATE CURVES
		return self:CalculateMagnitude(leftCurvePoints, j-1) + self:CalculateMagnitude(rightCurvePoints, j-1)
	else -- BASE CASE: JUST GET MAGNITUDE OF CURVE ITSELF
		return totalMagnitude
	end
end


function Projectile:Visualize(pos,
	parent: Instance?,
	size: Vector3?,
	color: Color3?
)

	parent = parent or workspace
	size = size or Vector3.new(0.5, 0.5, 0.5)
	color = color or Color3.fromRGB(0, 255, 0)


	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = color
	part.Position = pos
	part.Parent = parent

end


return Projectile
