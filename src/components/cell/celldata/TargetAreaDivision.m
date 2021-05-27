classdef TargetAreaDivision < AbstractCellData
	% Calculates the target area
	% If a cell is freshly divided, it takes the target area to be its current
	% area and stores this value for the entirety of the time when fraction = 0

	properties 

		name = 'targetArea'
		data = []

		pauseTargetArea = 0.5

	end

	methods

		function obj = TargetAreaDivision
			% No special initialisation
			
		end

		function CalculateData(obj, c)

			if c.GetAge() < 2 * c.CellCycleModel.dt
				obj.pauseTargetArea = c.GetCellArea();
			end


			fraction = c.CellCycleModel.GetGrowthPhaseFraction();

			obj.data = obj.pauseTargetArea + fraction * (c.grownCellTargetArea - obj.pauseTargetArea);

		end
		
	end

end