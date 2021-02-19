classdef WntCellCycle < AbstractCellCycleModel
	% A cell cycle with 2 phases, a growth phase and a pause phase
	% During the pause phase the cell is a constant size (or target size)
	% During the growing phase, the cell is increasing its volume (or target volume)

	% After a fresh division, the cell stays a constant size, for a time specified by
	% pausePhaseDuration, after which it starts growing

	% This offers a way to make cells stop growing after they reach a certain position
	% It is intended at this moment to be a quick hack to make cells stop growing in a crypt

	properties

		meanPausePhaseDuration
		pausePhaseDuration

		meanGrowingPhaseDuration
		growingPhaseDuration

		differentiated = false;

		height

		growthTriggerFraction = 1


		pauseColour
		growthColour
		inhibitedColour
		differentiatedColour

		dt

	end


	methods

		function obj = WntCellCycle(p, g, h, f, dt)
			obj.SetPausePhaseDuration(p);
			obj.SetGrowingPhaseDuration(g);
			obj.height = h;
			obj.growthTriggerFraction = f;
			obj.dt = dt;

			% By default cell will start off in the pause phase
			% (actually, this will depend somewhat on the randomly
			% chosen pausePhaselength)
			obj.SetAge(randi(p - 1));


			obj.pauseColour = obj.colourSet.GetNumber('PAUSE');
			obj.growthColour = obj.colourSet.GetNumber('GROW');
			obj.inhibitedColour = obj.colourSet.GetNumber('STOPPED');
			obj.differentiatedColour = obj.colourSet.GetNumber('DIFFERENTIATED');

		end

		% Redefine the AgeCellCycle method to update the phase colour
		% Could probably add in a phase tracking variable that gets updated here
		function AgeCellCycle(obj, dt)

			% Using the AgeCellCycle method, determine whether the cell is differentiated
			% by checking it's height. This is a quick hack to get it working.
			% The height is a proxy for Wnt concentration
			% The cell can only become differentiated if the cell is in the PAUSE phase
			% obj.age = obj.age + dt;
			% if ~obj.differentiated
			% 	c = obj.containingCell;
			% 	if obj.age > obj.pausePhaseDuration
			% 		obj.colour = obj.colourSet.GetNumber('GROW');
			% 	else
			% 		centre = obj.containingCell.GetCellCentre();
			% 		if centre(2) > obj.height
			% 			obj.differentiated = true;
			% 			obj.colour = obj.colourSet.GetNumber('STOPPED');
			% 		end
			% 	end
			% end


			obj.age = obj.age + dt;

			if ~obj.differentiated
				
				c = obj.containingCell;

				if obj.age < obj.pausePhaseDuration
					obj.colour = obj.pauseColour;
					
					centre = obj.containingCell.GetCellCentre();
					% If the cell is not already growing, and it passes
					% the limiting heigh for proliferation, then flag it as
					% differentiated
					if centre(2) > obj.height
						obj.differentiated = true;
						obj.colour = obj.differentiatedColour;
					end
					
				else

					if c.GetCellArea() < obj.growthTriggerFraction * c.newCellTargetArea
						% If it's too compressed, extend the pause phase
						% Since this already assumes the cell is at the end of
						% pause phase, this will occur when the cell is ready to
						% start growing, except for being to compressed
						obj.pausePhaseDuration = obj.pausePhaseDuration + obj.dt;
						obj.colour = obj.inhibitedColour;
					else
						obj.colour = obj.growthColour;
					end

				end

			end

		end

		function newCCM = Duplicate(obj)

			newCCM = WntCellCycle(obj.meanPausePhaseDuration, obj.meanGrowingPhaseDuration, obj.height, obj.growthTriggerFraction, obj.dt);
			newCCM.SetAge(0);
			newCCM.colour = obj.colourSet.GetNumber('PAUSE');

		end

		function ready = IsReadyToDivide(obj);

			ready = false;
			if ~obj.differentiated && obj.pausePhaseDuration + obj.growingPhaseDuration < obj.GetAge()
				ready = true;
			end

		end

		function fraction = GetGrowthPhaseFraction(obj)

			if obj.age < obj.pausePhaseDuration || obj.differentiated
				fraction = 0;
				% obj.colour = obj.colourSet.GetNumber('PAUSE');
			else
				fraction = (obj.age - obj.pausePhaseDuration) / obj.growingPhaseDuration;
			end

		end

		function SetPausePhaseDuration(obj, pt)

			obj.meanPausePhaseDuration = pt;

			% Normally distributed, but clipped
			wobble = normrnd(0,2);

			p = pt + wobble;

			if p < 1
				p = 1;
			end

			obj.pausePhaseDuration = p;

		end

		function SetGrowingPhaseDuration(obj, wt)
			% Wanted to call it gt, but apparently thats a reserved keyword in matlab...

			obj.meanGrowingPhaseDuration = wt;

			% Normally distributed, but clipped
			wobble = normrnd(0,2);

			g = wt + wobble;

			if g < 1
				g = 1;
			end

			obj.growingPhaseDuration = g;

		end

	end

end