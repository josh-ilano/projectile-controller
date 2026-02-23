local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Events = ReplicatedStorage:WaitForChild("Events")

local LocalPlayer = Players.LocalPlayer

local ProjectileLibrary = require(script.Parent.ProjectileLibrary)

local module = 
{
	
	projectileTrack = function(self, noCast) -- nocast allows us to manually cast w alias function so we don't automatically do it
		
		if self._castEffect and not noCast then self:Cast() end
		local midpoints, Projectile = self._clientProjectile(self._caster, self._target, self._args)
		
		if typeof(midpoints[1]) ~= "table" then midpoints = {midpoints} end
		local PC_Table = ProjectileLibrary[self._moveName](self, table.unpack(midpoints))

		local yield = Instance.new("BindableEvent")
	
		for i, PC in PC_Table do -- for every projectile in the table of projectiles...
			local intermediateTarget = PC._end -- in case you want to apply an effect to the targets in between
			local impactEvent: BindableEvent = PC:VisualizeMotion(Projectile) -- SUBPATHS
				
			impactEvent.Event:Once(function(...) 
				if i == #PC_Table and self._impactEffect then  -- TARGET RECEIVES DAMAGE
					
					if self._castingPlayer == LocalPlayer then
						Events.ApplyMove:FireServer(self._target)
					end
					self._impactEffect(Projectile, self._target, self._args)
					
				
				elseif self._intermediateEffect then self._intermediateEffect(Projectile, intermediateTarget) end
				

				impactEvent:Destroy()
				yield:Fire() -- GO ONTO THE NEXT PATH AFTER REACHING DESTINATION
			end)
			
			yield.Event:Wait()
		end
		yield:Destroy()
		

	end,
	
	projectileTrackTrail = function(self) -- DOES NOT SUPPORT MULTISTAGE TRAILS
		local midpoints, Projectile, moveFunc = self._clientProjectile(self._caster, self._target)
		local PC = ProjectileLibrary[self._moveName](self, midpoints)

		local impactEvent: BindableEvent, projectiles = PC:VisualizeTrail(Projectile, moveFunc, 5)
		impactEvent.Event:Once(function(...) 
			self._impactEffect(projectiles, self._target)
			impactEvent:Destroy()
		end)
	end,

	
	
}

return module
