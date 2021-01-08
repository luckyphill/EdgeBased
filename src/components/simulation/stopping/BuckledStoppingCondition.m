classdef BuckledStoppingCondition < AbstractStoppingCondition
	% This class gives the details for how stopping conditions
	% must be implemented

	properties
		% The ratio of centre line length to width
		ratio

		name = 'Buckling'

	end

	methods

		function obj = BuckledStoppingCondition(ratio)

			obj. ratio = ratio;
		end

		function stopped = HasStoppingConditionBeenMet(obj, t)

			stopped = false;

			w = t.simData('wiggleRatio');

			if w.GetData(t) > obj.ratio
				
				stopped = true;
			
			end

		end

	end



end