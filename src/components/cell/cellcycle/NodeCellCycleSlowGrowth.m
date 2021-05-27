classdef NodeCellCycleSlowGrowth < AbstractCellCycleModel
	% A cell cycle for node cells

	% This cell cycle is specifcally for NodeCells where the
	% growth happens after a new node is introduced.
	% This means that the actual growth is represented by controlling
	% separation between the two cells

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

		function obj = NodeCellCycleSlowGrowth(p, g, f, dt)

			% Need this annoying way of setting default values because
			% of a matlab quirk
			obj.pausePhaseRNG = @() unifrnd(-2,2);
			obj.growthPhaseRNG = @() unifrnd(-2,2);

			obj.SetPausePhaseDuration(p);
			obj.SetGrowthPhaseDuration(g);

			obj.growthTriggerFraction = f;

			obj.dt = dt;

			% By default cell will start off in the pause phase
			% which for a node cell will be the second half of the cycle
			obj.SetAge(round(obj.growthPhaseDuration + unifrnd(0,obj.pausePhaseDuration),1));

			obj.pauseColour = obj.colourSet.GetNumber('PAUSE');
			obj.growthColour = obj.colourSet.GetNumber('GROW');
			obj.inhibitedColour = obj.colourSet.GetNumber('STOPPED');


		end

		function newCCM = Duplicate(obj)

			% This where things need to get tricky
			% Technically after division, the cell hasn't really divided, its just
			% made up of two cells, so we need to make sure that the growth phases
			% the same length for the two new cells so their separation can be controlled properly

			newCCM = NodeCellCycleSlowGrowth(obj.meanPausePhaseDuration, obj.meanGrowthPhaseDuration, obj.growthTriggerFraction, obj.dt);
			newCCM.SetAge(0);
			newCCM.pauseColour = obj.pauseColour;
			newCCM.growthColour = obj.growthColour;
			newCCM.inhibitedColour = obj.inhibitedColour;
			
			% After division, the two new cells actually represent a single growing cell
			newCCM.colour = obj.growthColour;
			obj.colour = obj.growthColour;

			% We force the existing cell to have the same growth phase length as
			% the new cell to ensure they end the special interaction control
			% at the same moment
			obj.SetPausePhaseDuration(obj.meanPausePhaseDuration);
			obj.growthPhaseDuration = newCCM.growthPhaseDuration;

		end

		function ready = IsReadyToDivide(obj)

			% Node cells are weird in that they technically
			% need to divide before they can grow since a single node
			% can't really grow in size unless you increase the radius
			% If you do that, then on division the volume covered by the
			% cell goes from circular, to dumbell shaped where the dumbells
			% are smaller than the original size

			ready = false;
			if obj.pausePhaseDuration + obj.growthPhaseDuration < obj.GetAge()
				ready = true;
			end

		end


		% Redefine the AgeCellCycle method to update the phase colour
		% Could probably add in a phase tracking variable that gets updated here
		function AgeCellCycle(obj, dt)

			obj.age = obj.age + dt;

			if obj.age < obj.growthPhaseDuration
				obj.colour = obj.growthColour;
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
					obj.colour = obj.pauseColour;
				end
			end

		end

		function fraction = GetGrowthPhaseFraction(obj)

			fraction = 0;

			if obj.age < obj.growthPhaseDuration
				fraction = obj.age / obj.growthPhaseDuration;
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
				g = obj.minimumGrowthPhaseDuration;
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