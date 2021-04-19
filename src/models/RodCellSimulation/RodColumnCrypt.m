classdef RodColumnCrypt < FreeCellSimulation

	% An attempt to use the over-lapping rods model to replicate the column model

	properties

		% None yet...

	end

	methods

		function obj = RodColumnCrypt(seed)

			% Other parameters
			% Growth start time
			t0 = 10;
			tg = 10;

			b = 10;

			% The asymptote, separation, and limit distances for the interaction force
			dAsym = 0;
			dSep = 1;
			dLim = dSep;

			a = 10;
			s = 10;
			r = 10;

			f = 0;

			l = 2;

			obj.SetRNGSeed(seed);

			n1 = Node(0, 0, obj.GetNextNodeId());
			n2 = Node(0, l, obj.GetNextNodeId());

			e = Element(n1,n2,obj.GetNextElementId());

			obj.nodeList = [obj.nodeList, n1, n2];
			obj.elementList = [obj.elementList, e];

			ccm = GrowthContactInhibition(t0, tg, f, obj.dt);
			ccm.SetAge(t0);

			c = RodCell(e,ccm,obj.GetNextCellId());
			% When the cell areas are calculated, the length of the edge and
			% the radius from the preferred separation are both accounted for
			% so we can use the actual intended area here
			c.AddCellData(TargetAreaSpecified(dSep + 0.1, 2*dSep));
			c.newCellTargetArea = 0.5*l;
			c.grownCellTargetArea = l;
			c.preferredSeperation = dSep;
			
			obj.cellList = [obj.cellList, c];


			% Node-Element interaction force - requires a SpacePartition
			obj.AddNeighbourhoodBasedForce(CellCellInteractionForce(a, s, dAsym, dSep, dLim, obj.dt, false));

			% Flat boundary representing the membrane
			point = [0,0];
			normal = [1,0];
			obj.AddTissueBasedForce(FlatPlaneForceRod(b, point, normal, dAsym, dSep, 2*dLim));

			% A force to keep the rod cell at its preferred length
			obj.AddCellBasedForce(RodCellGrowthForce(r));

			point = [0,5];
			normal = [0,1];
			obj.AddCellKiller(PlaneCellKiller(point, normal));

			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			
			obj.boxes = SpacePartition(2, 2, obj);

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			pathName = sprintf('RodColumnCrypt/test_%d/',seed);
			obj.AddSimulationData(SpatialState());
			obj.AddDataWriter(WriteSpatialState(20, pathName));



		end
		
	end

end