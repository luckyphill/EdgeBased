classdef AbstractCellBasedForce < matlab.mixin.Heterogeneous
	% This class gives the details for how a force will be applied
	% to each cell (as opposed to each element, or the whole population)


	properties


	end

	methods (Abstract)

		AddCellBasedForces(obj, cellList)

	end



end