classdef StoreCircularity < AbstractDataStore
	% Stores the wiggle ratio

	properties

		% No special properties
		
	end

	methods

		function obj = StoreCircularity(sm)

			obj.samplingMultiple = sm;
			obj.data = [];

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% calculating the wiggle ratio

			% Update the wiggle ratio data object

			obj.data(end + 1) = t.simData('circularity').GetData(t);

		end
		
	end

end