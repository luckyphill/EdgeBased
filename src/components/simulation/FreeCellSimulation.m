classdef FreeCellSimulation < AbstractCellSimulation

	% This uses free cells, i.e. cells that never share
	% elemetns or node with other cells

	properties

		dt = 0.005
		t = 0
		step = 0

	end

	methods

		function obj  = FreeCellSimulation()

			% Special initialisation when I work out what it needs
		end

		function c = MakeCellAtCentre(obj, N, x,y, ccm)

			pgon = nsidedpoly(N, 'Radius', 0.5);
			v = flipud(pgon.Vertices); % Necessary for the correct order

			nodes = Node.empty();

			for i = 1:N
				nodes(i) = Node(v(i,1) + x, v(i,2) + y, obj.GetNextNodeId());
			end

			c = CellFree(ccm, nodes, obj.GetNextCellId());

		end
		
	end

end