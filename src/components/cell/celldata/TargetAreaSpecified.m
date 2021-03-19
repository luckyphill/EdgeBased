classdef TargetAreaSpecified < AbstractCellData
	% Calculates the wiggle ratio

	properties 

		name = 'targetArea'
		data = []

		% The specified target areas for a new cell and a grown cell
		newCell
		grownCell

	end

	methods

		function obj = TargetAreaSpecified(newCell, grownCell)
			obj.newCell = newCell;
			obj.grownCell = grownCell;
			
		end

		function CalculateData(obj, c)

			fraction = c.CellCycleModel.GetGrowthPhaseFraction();

			obj.data = c.newCell + fraction * (obj.grownCell - obj.newCell);

		end
		
	end

end