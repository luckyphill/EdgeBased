classdef (Abstract) AbstractNodeData < handle & matlab.mixin.Heterogeneous
	% This class sets out the required functions for working
	% out various types of data that can be extracted from the 
	% a node. A node only has useful information when it is part of a
	% tissue (or organ after doing the refactoring), so this 
	% requires a tissue to be handed in

	% This is initially for neigbours. It shouldn't be used for things
	% that don't really need calculating

	% If we put the calculate operation in the get operation,
	% then we might end up calculating multiple times per time step
	% if the data is used in multiple places. To avoid this, we add in
	% an age stamp for when the data was last calculated

	properties (Abstract)

		% A unique identifier so the data can be accessed
		% in a way that has a meaningful interpretation
		% instead of an index
		name

		% A structure that holds the data within a timestep
		data

	end

	properties

		% The last time point when the data was calculated
		% saves calculating repeatedly in a single time step
		stepStamp = -1

	end


	methods (Abstract)

		% This method must return data
		CalculateData(obj, n, t)
		
	end

	methods

		function val = GetData(obj, n, t)

			if obj.stepStamp == t.step
				val = obj.data;
			else
				obj.stepStamp = t.step;
				obj.CalculateData(n, t);
				val = obj.data;
			end

		end

	end

end