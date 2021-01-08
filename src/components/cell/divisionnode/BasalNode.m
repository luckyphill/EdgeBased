classdef BasalNode < AbstractSplitNode < handle
	% This class sets out the required functions for working
	% out the node in a free cell where division starts from



	methods

		function obj = BasalNode()

		end

		function [n, i] = GetSplitNode(obj,c)

			% Loops through the nodes, and determines which nodes are
			% attached to the basement membrane

			% Place holder random selection
			i = randi( length(c.nodeList) );
			n = c.nodeList(  i  );

		end

	end

end