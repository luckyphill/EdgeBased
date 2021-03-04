classdef StoreCellGeometry < AbstractDataStore
	% Stores the wiggle ratio

	properties

		% No special properties
		
	end

	methods

		function obj = StoreCellGeometry(sm)

			obj.samplingMultiple = sm;
			obj.data = [];

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% calculating the wiggle ratio

			obj.data(end + 1) = t.simData('cellGeometry').GetData(t);

		end
		
	end

end