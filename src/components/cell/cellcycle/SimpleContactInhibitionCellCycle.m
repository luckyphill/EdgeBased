classdef SimpleContactInhibitionCellCycle < AbstractCellCycleModel
	% A cell cycle with 2 phases, a growth phase and a pause phase
	% During the pause phase the cell is a constant size (or target size)
	% During the growing phase, the cell is increasing its volume (or target volume)

	% After a fresh division, the cell stays a constant size, for a time specified by
	% pausePhaseDuration, after which it starts growing

	properties

		meanPausePhaseDuration
		pausePhaseDuration

		meanGrowthPhaseDuration
		growthPhaseDuration

		minimumPausePhaseDuration = 0
		minimumGrowthPhaseDuration = 4

		pausePhaseRNG = rand
		growthPhaseRNG = rand

		growthTriggerFraction

		dt

		pauseColour
		growthColour
		inhibitedColour

	end


	methods

		function obj = SimpleContactInhibitionCellCycle(p, g, f, dt)

			% Need this annoying way of setting default values because
			% of a matlab quirk
			obj.pausePhaseRNG = @() unifrnd(-2,2);
			obj.growthPhaseRNG = @() unifrnd(-2,2);

			obj.SetPausePhaseDuration(p);
			obj.SetGrowthPhaseDuration(g);

			obj.growthTriggerFraction = f;

			obj.dt = dt;

			% By default cell will start off in the pause phase
			obj.SetAge(round(unifrnd(0,obj.pausePhaseDuration),1));

			obj.pauseColour = obj.colourSet.GetNumber('PAUSE');
			obj.growthColour = obj.colourSet.GetNumber('GROW');
			obj.inhibitedColour = obj.colourSet.GetNumber('STOPPED');

		end

		% Redefine the AgeCellCycle method to update the phase colour
		% Could probably add in a phase tracking variable that gets updated here
		function AgeCellCycle(obj, dt)

			obj.age = obj.age + dt;

			if obj.age < obj.pausePhaseDuration
				obj.colour = obj.pauseColour;
			else
				c = obj.containingCell;
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

		function newCCM = Duplicate(obj)

			newCCM = SimpleContactInhibitionCellCycle(obj.meanPausePhaseDuration, obj.meanGrowthPhaseDuration, obj.growthTriggerFraction, obj.dt);
			newCCM.SetAge(0);
			newCCM.pauseColour = obj.pauseColour;
			newCCM.growthColour = obj.growthColour;
			newCCM.inhibitedColour = obj.inhibitedColour;
			
			newCCM.colour = obj.pauseColour;

			obj.colour = obj.pauseColour;
			obj.SetPausePhaseDuration(obj.meanPausePhaseDuration);
			obj.SetGrowthPhaseDuration(obj.meanGrowthPhaseDuration);

		end

		function ready = IsReadyToDivide(obj);

			ready = false;
			if obj.pausePhaseDuration + obj.growthPhaseDuration < obj.GetAge()
				ready = true;
			end

		end

		function fraction = GetGrowthPhaseFraction(obj)

			if obj.age < obj.pausePhaseDuration
				fraction = 0;
			else
				fraction = (obj.age - obj.pausePhaseDuration) / obj.growthPhaseDuration;
			end

		end

		function SetPausePhaseDuration(obj, p)

			obj.meanPausePhaseDuration = p;

			p = p + obj.pausePhaseRNG();

			if p < obj.minimumPausePhaseDuration
				p = obj.minimumPausePhaseDuration;
			end

			obj.pausePhaseDuration = p;

		end

		function SetGrowthPhaseDuration(obj, g)

			obj.meanGrowthPhaseDuration = g;

			g = g + obj.growthPhaseRNG();

			if g < obj.minimumGrowthPhaseDuration
				g = obj.minimumGrowthPhaseDuration
			end

			obj.growthPhaseDuration = g;

		end

		function set.pausePhaseRNG(obj, func)

			obj.pausePhaseRNG = func;
			obj.SetPausePhaseDuration(obj.meanPausePhaseDuration);

		end

		function set.growthPhaseRNG(obj, func)

			obj.growthPhaseRNG = func;
			obj.SetGrowthPhaseDuration(obj.meanGrowthPhaseDuration);

		end

	end

end