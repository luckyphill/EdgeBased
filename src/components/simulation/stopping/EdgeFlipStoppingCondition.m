classdef EdgeFlipStoppingCondition < AbstractStoppingCondition
	% Detects if an edge has flipped on a cell

	properties

		name = 'EdgeFlip'
	end

	methods

		function obj = EdgeFlipStoppingCondition()
			% Nothing to initialise

		end

		function stopped = HasStoppingConditionBeenMet(obj, t)

			% If an edge has flipped, that means the cell is no longer a physical shape
			% so we need to detect this and stop the simulation

			stopped = false;
			i = 1;
			while ~stopped && i <= t.GetNumCells()

				stopped = t.cellList(i).HasEdgeFlipped();

				i = i + 1;

			end

		end

	end



end