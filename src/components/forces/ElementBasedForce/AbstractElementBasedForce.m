classdef AbstractElementBasedForce < matlab.mixin.Heterogeneous
	% This class gives the details for how a force will be applied
	% to each Element (as opposed to each cell, or the whole population)


	properties


	end

	methods (Abstract)

		AddElementBasedForces(obj, cellList)

	end



end