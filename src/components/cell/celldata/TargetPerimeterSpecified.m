classdef TargetPerimeterSpecified < AbstractCellData
	% Target perimeter for the general case with CellFree etc.

	properties 

		name = 'targetPerimeter'
		data = []
		new
		grown

	end

	methods

		function obj = TargetPerimeterSpecified(new, grown)
			% No special initialisation
			obj.new = new;
			obj.grown = grown;
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			fraction = c.CellCycleModel.GetGrowthPhaseFraction();


			obj.data = obj.new + fraction * (obj.grown - obj.new);

		end
		
	end

end