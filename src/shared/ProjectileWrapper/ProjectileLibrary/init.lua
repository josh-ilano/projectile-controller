local Players = game:GetService('Players')
local Debris = game:GetService('Debris')

local ProjectileFixed = require(script.ProjectileFixed)
local ProjectileTracked = require(script.ProjectileTracked)

local ProjectileLibrary = {}

ProjectileLibrary.TealProjectile = function(self, midpoints)
	return 
		{ProjectileTracked.new("Cubic",
		midpoints,
		self._caster, 
		self._target,
		20)}
end

ProjectileLibrary.Blast = function(self, midpoints)
	return
		{ProjectileTracked.new("Quartic",
		midpoints,
		self._caster, 
		self._target,
		80)}
end

ProjectileLibrary.Mindblast = function(self, midpoints)
	return 
		ProjectileTracked.new("Quartic",
		midpoints,
		self._caster, 
		self._target,
		10)

end

ProjectileLibrary.PoisonArrow = function(self, midpoints, secondMidpoints: Vector3?)
	
	local b_attachment = Instance.new("Attachment")
	b_attachment.Position = Vector3.new(0,50,0)
	b_attachment.Parent = self._target
	Debris:AddItem(b_attachment, 15)

	return 
		{ProjectileTracked.new("Quartic",
			midpoints,
			self._caster, 
			b_attachment,
			50),
		
		ProjectileTracked.new("Quad",
			secondMidpoints,
			b_attachment, 
			self._target,
			100)}
	
	
end

ProjectileLibrary.Fireball = function(self)
	return {ProjectileTracked.new("Linear",
		{},
		self._caster, 
		self._target,
		50)}
end

ProjectileLibrary.Missile = function(self)
	return {ProjectileTracked.new("Linear",
		{},
		self._caster, 
		self._target,
		50)}
end

ProjectileLibrary.Suna = function(self)
	return {ProjectileTracked.new("Linear",
		{},
		self._caster, 
		self._target,
		50)}
end

ProjectileLibrary.Bloodlust = function(self)
	local targetPos = self._target.PrimaryPart.Position

	return {ProjectileTracked.new("Linear",
		{},
		targetPos + Vector3.new(0,15,0), 
		self._target,
		30)}
end

ProjectileLibrary.Ayaka = function(self)
	
	
	local casterCFrame: CFrame = self._caster.PrimaryPart.CFrame
	
	local casterDic = {
		[1] = casterCFrame + (casterCFrame.LookVector * 30) + (casterCFrame.RightVector * -20),
		[2] = casterCFrame + (casterCFrame.LookVector * 35) ,
		[3] = casterCFrame + (casterCFrame.LookVector * 30) + (casterCFrame.RightVector * 20)	
	}
	
	local targetPos = self._target.PrimaryPart.Position
	local index = self._args[1]

	return {ProjectileTracked.new("Linear",
		{},
		casterDic[index].Position, 
		self._target,
		20)}
end


ProjectileLibrary.LightRay = function(self)
	
	local projectileTable = {}
	
	local numTargets = #self._args-1
	
	
	-- THE MINIMUM AMOUNT OF ARGS IS 2, AS THE LAST ELEMENT THE ACTUAL PROJECTILE ITSELF
	if numTargets == 1 then
		table.insert(projectileTable, -- ADD FROM POINT A TO A, BASICALLY TRANSITIONING IMMEDIATELY TO IMPACT
			ProjectileTracked.new("Linear",
				{},
				self._args[1].attachment, 
				self._args[1].attachment,
				20)	
		)
	else
		for index, healInfo in self._args do
			if index < numTargets then
				table.insert(projectileTable, -- ADD FROM POINT A TO B 
					ProjectileTracked.new("Linear",
						{},
						healInfo.attachment, 
						self._args[index+1].attachment, -- technically on last iteration this is self._target
						20)	
				)
			end
		end
	end
		
	return projectileTable
	
end

return ProjectileLibrary
