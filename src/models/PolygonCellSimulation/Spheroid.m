classdef Spheroid < FreeCellSimulation

	% This uses free cells, i.e. cells that never share
	% elemetns or node with other cells

	properties

		% None yet...

	end

	methods

		function obj = Spheroid(t0, tg, s, sreg, seed)

			% Object input paramters can be chosen as desired. These are the
			% most useful ones for tuning behaviour and running tests

			% Set the rng seed for reproducibility
			obj.SetRNGSeed(seed);

			% t0 is the pause phase duration
			% tg is the growth phase duration
			% s is the cell-cell interaction force law parameter used for both adhesion and repulsion
			% sreg is the perimeter normalising force

			% Other parameters
			% Contact inhibition fraction
			f = 0.9;

			% The asymptote, separation, and limit distances for the interaction force
			dAsym = -0.1;
			dSep = 0.1;
			dLim = 0.2;

			% The energy densities for the cell growth force
			areaEnergy = 20;
			perimeterEnergy = 10;
			tensionEnergy = 1;

			
			% Make nodes around a polygon
			N = 10;
			X = [0, 1, 0, 1];
			Y = [0, 0, 1, 1];

			for i = 1:length(X)
				x = X(i);
				y = Y(i);
				
				ccm = GrowthContactInhibition(t0, tg, f, obj.dt);
				

				c = MakeCellAtCentre(obj, N, x + 0.5 * mod(y,2), y * sqrt(3)/2, ccm);

				obj.nodeList = [obj.nodeList, c.nodeList];
				obj.elementList = [obj.elementList, c.elementList];
				obj.cellList = [obj.cellList, c];

			end

			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Cell growth force
			obj.AddCellBasedForce(PolygonCellGrowthForce(areaEnergy, perimeterEnergy, tensionEnergy));


			% Node-Element interaction force - requires a SpacePartition
			obj.AddNeighbourhoodBasedForce(CellCellInteractionForce(s, s, dAsym, dSep, dLim, obj.dt, true));

			% Self explanitory, really. Tries to make the edges the same length
			obj.AddCellBasedForce(FreeCellPerimeterNormalisingForce(sreg));
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			
			obj.boxes = SpacePartition(0.3, 0.3, obj);

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------
			pathName = sprintf('Spheroid/t0%gtg%gs%gsreg%gf%gda%gds%gdl%ga%gb%gt%g_seed%g/',t0,tg,s,sreg,f,dAsym,dSep, dLim, areaEnergy, perimeterEnergy, tensionEnergy, seed);
			obj.AddSimulationData(SpatialState());
			obj.AddDataWriter(WriteSpatialState(20, pathName));



		end
		
	end

end