classdef PinNodes < AbstractSimulationModifier
	% This modifier makes the boundary nodes for the left and
	% right boundary cells have the same y position
	% In theory this will stop a buckled monolayer from flapping about
	% and will simulate - to some extent - the stabilising influence
	% of a stromal underlayer

	properties

		% No special properties
		nodeList
	end

	methods

		function obj = PinNodes(nodeList)

			obj.nodeList = nodeList;

		end

		function ModifySimulation(obj, t)

			% This keeps the specified nodes locked in place
			% by moving them back to their previous position after movement

			for i = 1:length(obj.nodeList)
				n = obj.nodeList(i);
				t.AdjustNodePosition(n, n.previousPosition);
			end
			
		end

	end

end