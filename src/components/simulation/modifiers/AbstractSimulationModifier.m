classdef AbstractSimulationModifier < matlab.mixin.Heterogeneous
	% This class sets out the required functions for modifying
	% a simulation

	% Since this is directly changing the simulation state,
	% there may be instances when multiple modifiers interact
	% Caution needs to be observed 

	methods  (Abstract)

		ModifySimulation(obj, t);
		
	end

end