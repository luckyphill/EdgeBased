classdef DeltaRatio < AbstractSimulationData
	% Gets the number of cells

	properties 

		name = 'deltaRatio'
		data = []
	end

	methods

		function obj = DeltaRatio
			% No special initialisation
		end

		function CalculateData(obj, t)


			count = length(t.cellList);
			height = t.simData('cryptHeight').GetData(t);

			obj.data = count/height;

		end
		
	end


end