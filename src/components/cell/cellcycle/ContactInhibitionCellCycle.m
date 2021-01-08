classdef ContactInhibitionCellCycle < AbstractCellCycleModel
	% A cell cycle with 2 phases, a growth phase and a pause phase
	% During the pause phase the cell is a constant size (or target size)
	% During the growing phase, the cell is increasing its volume (or target volume)

	% After a fresh division, the cell stays a constant size, for a time specified by
	% pausePhaseLength, after which it starts growing

	properties

		meanPausePhaseLength
		pausePhaseLength

		meanGrowingPhaseLength
		growingPhaseLength

		growthTriggerFraction

		dt

	end


	methods

		function obj = ContactInhibitionCellCycle(p, g, f, dt)
			obj.SetPausePhaseLength(p);
			obj.SetGrowingPhaseLength(g);

			obj.growthTriggerFraction = f;

			obj.dt = dt;

			% By default cell will start off in the pause phase
			% (actually, this will depend somewhat on the randomly
			% chosen pausePhaselength)
			obj.SetAge(round(unifrnd(0,p - 1),1));

		end

		% Redefine the AgeCellCycle method to update the phase colour
		% Could probably add in a phase tracking variable that gets updated here
		function AgeCellCycle(obj, dt)

			obj.age = obj.age + dt;

		end

		function newCCM = Duplicate(obj)

			newCCM = ContactInhibitionCellCycle(obj.meanPausePhaseLength, obj.meanGrowingPhaseLength, obj.growthTriggerFraction, obj.dt);
			newCCM.SetAge(0);
			newCCM.colour = obj.colourSet.GetNumber('PAUSE');

			obj.colour = obj.colourSet.GetNumber('PAUSE');
			obj.SetPausePhaseLength(obj.meanPausePhaseLength);
			obj.SetGrowingPhaseLength(obj.meanGrowingPhaseLength);

		end

		function ready = IsReadyToDivide(obj);

			ready = false;
			if obj.pausePhaseLength + obj.growingPhaseLength < obj.GetAge()
				ready = true;
			end

		end

		function fraction = GetGrowthPhaseFraction(obj)

			if obj.age < obj.pausePhaseLength
				fraction = 0;
				obj.colour = obj.colourSet.GetNumber('PAUSE');
			else
				c = obj.containingCell;
				if  ( obj.colour ~= obj.colourSet.GetNumber('GROW') ) && ( c.GetCellArea() < obj.growthTriggerFraction * c.newCellTargetArea )
					% Bit of a hacky way around since the phase is indirectly tied to the colour but it should work
					obj.pausePhaseLength = obj.pausePhaseLength + obj.dt;
					obj.colour = obj.colourSet.GetNumber('STOPPED');
					fraction = 0;
				else
					fraction = (obj.age - obj.pausePhaseLength) / obj.growingPhaseLength;
					obj.colour = obj.colourSet.GetNumber('GROW');
				end
			end

		end

		function SetPausePhaseLength(obj, pt)

			obj.meanPausePhaseLength = pt;

			% Normally distributed, but clipped
			wobble = normrnd(0,2);

			p = pt + wobble;

			if p < 1
				p = 1;
			end

			obj.pausePhaseLength = p;

		end

		function SetGrowingPhaseLength(obj, wt)
			% Wanted to call it gt, but apparently thats a reserved keyword in matlab...

			obj.meanGrowingPhaseLength = wt;

			% Normally distributed, but clipped
			wobble = normrnd(0,2);

			g = wt + wobble;

			if g < 1
				g = 1;
			end

			obj.growingPhaseLength = g;

		end

	end

end