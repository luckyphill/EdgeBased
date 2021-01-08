classdef NodeCellCycle < AbstractCellCycleModel
	% A cell cycle for node cells

	properties

		cycleLength
	end

	methods

		function obj = NodeCellCycle(cL)

			obj.SetAge(cL*rand);
			obj.cycleLength = cL;

		end

		function newCCM = Duplicate(obj)

			newCCM = NodeCellCycle(obj.cycleLength);
			newCCM.SetAge(obj.cycleLength*rand);
			obj.SetAge(obj.cycleLength*rand);

		end

		% Cell cycle mode does nothing, so it never divides
		function ready = IsReadyToDivide(obj)

			ready = false;
			if obj.age > obj.cycleLength
				ready = true;
			end
		end

		function fraction = GetGrowthPhaseFraction(obj)

			fraction = 1;
		end

	end


end