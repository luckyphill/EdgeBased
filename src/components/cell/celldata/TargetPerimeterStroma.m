classdef TargetPerimeterStroma < AbstractCellData
	% Target perimeter for the general case with CellFree etc.

	properties 

		name = 'targetPerimeter'
		data = []
		target

	end

	methods

		function obj = TargetPerimeterStroma(p)
			
			% As a hack to get it working, going to set the target
			% perimeter to be whatever it was initially

			obj.target = p;
			
		end

		function CalculateData(obj, c)

			obj.data = obj.target;

		end
		
	end

end