local ProjectileInvoker = require(script.ProjectileInvoker)


local ProjectileWrapper = {}
ProjectileWrapper.__index = ProjectileWrapper


function ProjectileWrapper.new(castingPlayer, caster, target, moveName: string, changeCaster: boolean?, args)
	
	local move = require(script.Parent.Effects[moveName])
	
	local self = setmetatable({
		_castingPlayer = castingPlayer,
		
		_caster = caster, 
		_target = target,
		_moveName = moveName,
		_castEffect = move.Cast,
		_clientProjectile  = move.Projectile,
		
		_intermediateEffect = move.Intermediate, -- ONLY FOR MULTISTAGE CURVES
		_impactEffect = move.Impact,
		_endCastEffect = move.End, -- FOR MOVES THAT HAVE AN ADDITIONAL STAGE BEYOND IMPACT
		
		_args = args or {}

	}, ProjectileWrapper)

	if move.Initialize then 
		-- WE CHANGE THE SOURCE OF THE CASTER
		-- e.g. changing the source from the character themselves to a magical weapon that is summoned
		local returnedObject = move.Initialize(self._caster, self._target)
		if changeCaster then self._caster = returnedObject end
		table.insert(self._args, returnedObject) -- ADD INITIALIZED OBJECT AS AN ARG JUST FOR EXTRANEOUS USE
	end

	return self
end

function ProjectileWrapper:Cast() -- apply an effect on caster
	self._castEffect(self._caster, self._args)
end

function ProjectileWrapper:EndCast() -- apply an effect on caster
	self._endCastEffect(self._caster)
end


local ProjectileWrapperLibrary = {
	["TealProjectile"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Blast"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Mindblast"] = function(self) ProjectileInvoker.projectileTrackTrail(self) end,
	["PoisonArrow"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Fireball"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Missile"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Suna"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Bloodlust"] = function(self) ProjectileInvoker.projectileTrack(self, true) end,
	["LightRay"] = function(self) ProjectileInvoker.projectileTrack(self) end,
	["Ayaka"] = function(self) ProjectileInvoker.projectileTrack(self) end
}




local TRACKED_MOVES = {
	TealProjectile = {
		iterations = 6,
		delay = 0.185
	},

	Blast = {
		iterations = 10,
		delay = 0.01
	},

	Mindblast = {
		iterations = 3,
		delay = 0.01
	},

	Bloodlust = {
		iterations = 10,
		delay = 0.4
	},
	
	PoisonArrow = {
		iterations = 5,
		delay = 0
	},
	
	Ayaka = {
		iterations = 3,
		delay = 0
	}
}



function ProjectileWrapper:Track()
	local trackInfo = TRACKED_MOVES[self._moveName] or {}
	for i=1, trackInfo.iterations or 1 do 	
		if self._moveName == "Ayaka" then self._args[1] = i end
		
		task.defer(function()
			ProjectileWrapperLibrary[self._moveName](self)		
		end)
		task.wait(trackInfo.delay or 0)
	end
end

return ProjectileWrapper