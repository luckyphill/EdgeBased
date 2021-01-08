classdef NoCellCycle < AbstractCellCycleModel
	% A cell cycle that does nothing except count the age of the cell

	methods

		function obj = NoCellCycle()

			obj.SetAge(0);

		end

		function newCCM = Duplicate(obj)

			newCCM = NoCellCycle();

		end

		% Cell cycle mode does nothing, so it never divides
		function ready = IsReadyToDivide(obj)

			ready = false;
		end

		function fraction = GetGrowthPhaseFraction(obj)

			fraction = 1;
		end

	end


end