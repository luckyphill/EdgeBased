classdef WntCellCycleNiche < AbstractCellCycleModel
	% Identical to WntCellCycle except the niche doesn't allow division

	properties

		meanPausePhaseDuration
		pausePhaseDuration

		meanGrowingPhaseDuration
		growingPhaseDuration

		differentiated = false;

		growthTriggerFraction = 1


		pauseColour
		growthColour
		inhibitedColour
		differentiatedColour
		mutatedColour

		tissue % A pointer to the whole simulation

		nicheHeight = 1.5

	end


	methods

		function obj = WntCellCycleNiche(p, g, f, t)
			obj.SetPausePhaseDuration(p);
			obj.SetGrowingPhaseDuration(g);
			obj.growthTriggerFraction = f;
			
			obj.tissue = t;

			% By default cell will start off in the pause phase
			% (actually, this will depend somewhat on the randomly
			% chosen pausePhaselength)
			obj.SetAge(randi(p - 1));


			obj.pauseColour = obj.colourSet.GetNumber('PAUSE');
			obj.growthColour = obj.colourSet.GetNumber('GROW');
			obj.inhibitedColour = obj.colourSet.GetNumber('STOPPED');
			obj.differentiatedColour = obj.colourSet.GetNumber('DIFFERENTIATED');
			obj.mutatedColour  = obj.colourSet.GetNumber('DYING');

		end

		% Redefine the AgeCellCycle method to update the phase colour
		% Could probably add in a phase tracking variable that gets updated here
		function AgeCellCycle(obj, dt)


			obj.age = obj.age + dt;

			c = obj.containingCell;

			if ~obj.differentiated

				if obj.age < obj.pausePhaseDuration
					obj.colour = obj.pauseColour;
					
					centre = obj.containingCell.GetCellCentre();
					% If the cell is not already growing, and it passes
					% the limiting heigh for proliferation, then flag it as
					% differentiated

					% Hacky, assumes the first cell is the stroma, which won't be true in general
					% but is true for DynamicCrypt
					heights = [obj.tissue.cellList(1).nodeList.y]; 
					base = sort(heights);
					base = base(3);
					if centre(2) > obj.tissue.simData('wntCutoff').GetData(obj.tissue) || centre(2) < base + obj.nicheHeight
						obj.differentiated = true;
						obj.colour = obj.differentiatedColour;
					end
					
				else

					if c.GetCellArea() < obj.growthTriggerFraction * c.newCellTargetArea
						% If it's too compressed, extend the pause phase
						% Since this already assumes the cell is at the end of
						% pause phase, this will occur when the cell is ready to
						% start growing, except for being to compressed
						obj.pausePhaseDuration = obj.pausePhaseDuration + obj.tissue.dt;
						obj.colour = obj.inhibitedColour;
					else
						obj.colour = obj.growthColour;
					end

				end

			else
				
				% Hold it in pause phase. Technically the cell is stopped in the niche
				% or differentiated zone, but its actually just prevented from leaving
				% pause. If the cell is in the niche it can move into the transient
				% amplifying region again, and start growth, so we need to keep adjusting
				% the length of the pause phase so we suddenly don't have an ancient cell
				% that wants to divide without going through the growth phase
				obj.pausePhaseDuration = obj.pausePhaseDuration + obj.tissue.dt;

				
				centre = obj.containingCell.GetCellCentre();
				% Hacky, assumes the first cell is the stroma, which won't be true in general
				% but is true for DynamicCrypt
				heights = [obj.tissue.cellList(1).nodeList.y]; 
				base = sort(heights);
				base = base(3);
				% If the cell is differentiated, it could be in the niche,
				% so we need to check if it's moved into the transit amplifying region
				if centre(2) > base + obj.nicheHeight && centre(2) < obj.tissue.simData('wntCutoff').GetData(obj.tissue)
					obj.differentiated = false;
					obj.colour = obj.pauseColour;
				end

			end


			if c.cellType == 2
				% Cell is a mutant
				obj.colour = obj.mutatedColour;
			end

		end

		function newCCM = Duplicate(obj)

			newCCM = WntCellCycleNiche(obj.meanPausePhaseDuration, obj.meanGrowingPhaseDuration, obj.growthTriggerFraction, obj.tissue);
			newCCM.SetAge(0);
			newCCM.colour = obj.colourSet.GetNumber('PAUSE');

			if obj.containingCell.cellType == 2
				% Cell is a mutant
				newCCM.colour = obj.mutatedColour;
			end

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