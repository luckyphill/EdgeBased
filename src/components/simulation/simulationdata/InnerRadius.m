classdef InnerRadius < AbstractModifiableSimulationData
	% Gets the number of cells

	properties 

		name = 'innerRadius'

		data = []
	end

	methods

		function obj = InnerRadius()
			% No special initialisation
		end

		function correct = DataIsValid(obj, d)

			% This is a radius, so it must be positive
			% but we allow for nans 
			if sum(isnan(d))
				correct = true;
			else
				correct = sum(d>0);
			end

		end
		
	end


end