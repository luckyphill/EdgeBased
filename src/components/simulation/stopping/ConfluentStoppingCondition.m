classdef ConfluentStoppingCondition < AbstractStoppingCondition
	% If all of the cells are in a state of contact inhibition
	% stop the simulation

	properties

		name = 'Confluent'

	end

	methods

		function obj = ConfluentStoppingCondition()

			% No special initialisation

		end

		function stopped = HasStoppingConditionBeenMet(obj, t)

			stopped = true;

			% Loop through the node cell population, and if any single cell is
			% not in the stopped condition, then the simulation continues.
			for i = 1:length(t.cellList)
				c = t.cellList(i);
				if isa(c, 'NodeCell')

					if (c.CellCycleModel.colour ~= c.CellCycleModel.colourSet.GetNumber('STOPPED'))
						stopped = false;
						break;
					end

				end

			end

		end

	end



end