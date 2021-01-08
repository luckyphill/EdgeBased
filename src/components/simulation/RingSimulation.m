classdef RingSimulation < AbstractCellSimulation

	% This type of simulation is a closed ring of cells
	% I wanted to call this an abstract class, but I can't make the constructor
	% I need, so here we are...

	properties

		step = 0

	end

	methods

		function obj  = RingSimulation()

			obj.AddSimulationData(CentreLineLoop());
			obj.AddSimulationData(StartCell());

		end
		
	end

end