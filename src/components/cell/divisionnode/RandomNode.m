classdef RandomNode < AbstractSplitNode
	% This class sets out the required functions for working
	% out the node in a free cell where division starts from



	methods

		function obj = RandomNode()

		end

		function [n, i] = GetSplitNode(obj,c)

			i = randi( length(c.nodeList) );
			n = c.nodeList(  i  );

		end

	end

end