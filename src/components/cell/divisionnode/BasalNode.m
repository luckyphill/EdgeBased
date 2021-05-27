classdef BasalNode < AbstractSplitNode

	methods

		function obj = BasalNode()

		end

		function [n, i] = GetSplitNode(obj, c)

			% Loops through the nodes, and chooses the lowest node in the cell
			% to be the split node

			lowestIdx = 0;
			lowestY = 100000000; % This will almost surely never be an issue

			for i = 1:length(c.nodeList)
				n = c.nodeList(  i  );
				if n.y < lowestY
					lowestY = n.y;
					lowestIdx = i;
				end
			end

			i = lowestIdx;
			n = c.nodeList(  lowestIdx  );
			
		end

	end

end