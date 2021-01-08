classdef (Abstract) AbstractSplitNode < matlab.mixin.Heterogeneous & handle
	% This class sets out the required functions for working
	% out the node in a free cell where division starts from



	methods (Abstract)

		% n must be the node, i must be the index for that node in c.nodeList
		[n, i] = GetSplitNode(obj,c);

	end

end