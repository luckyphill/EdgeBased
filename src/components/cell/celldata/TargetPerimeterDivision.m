classdef TargetPerimeterDivision < AbstractCellData
	% Calculates the target perimeter
	% If a cell is freshly divided, it takes the target perimeter to be its current
	% perimeter and stores this value for the entirety of the time when fraction = 0

	properties 

		name = 'targetPerimeter'
		data = []

		% Default set as the column shaped cell
		pauseTargetPerimeter = 3
		fullyGrownTargetPerimeter = 4

	end

	methods

		function obj = TargetPerimeterDivision
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			

			if c.GetAge() < 2 * c.CellCycleModel.dt
				obj.pauseTargetPerimeter = c.GetCellPerimeter();
			end


			fraction = c.CellCycleModel.GetGrowthPhaseFraction();

			obj.data = obj.pauseTargetPerimeter + fraction * (obj.fullyGrownTargetPerimeter - obj.pauseTargetPerimeter);


		end
		
	end

end