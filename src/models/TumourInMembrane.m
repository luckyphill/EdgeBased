classdef TumourInMembrane < AbstractCellSimulation

	% A model of cancerous cells constrained by a membrane



	properties

		dt = 0.005
		t = 0
		step = 0

		timeLimit = 500

		samplingMultiple = 100;

		pathName
		simulationOutputLocation

	end

	methods

		function obj  = TumourInMembrane(radius, t0, tg, mpe, f, dF, seed)

			% Input variables:
			% radius: the initial radius of the membrane
			% t0: The pause phase duration
			% tg: The growth phase duration
			% mpe: The membrane perimeter energy factor
			% f: The contact inhibition volume fraction
			% dF: the internal duct pressure parameter
			% seed: RNG seed

			% Each cell is represented by a single node
			% The membrane is represented by a contiguous ring of edges
			% to fit in with the tool, the Membrane object is a subclass of AbstractCell

			obj.SetRNGSeed(seed);

			nodeCellType 		= 1;
			membraneCellType 	= 6;

			% Assemble force law matrices for CellTypeInteractionForce
			cellTypes = [nodeCellType, membraneCellType];

			% Asymptote
			dA 			= 0;
			
			% Preferred Separation
			dSN 		= 1;
			dSNM 		= 0.5;
			dSM 		= 0.2;
			
			% Limiting range
			dLN 		= 1.2;
			dLNM 		= 0.6;
			dLM			= 0.5;

			% Attraction
			aN 			= 5;
			aNM 		= 10;
			aM 			= 0;

			% Repulsion
			r 			= 10;

			% Assemble these into matrices for CellTypeInteractionForce
			att 		= [aN,aNM;
				   	   	   aNM,aM]; 			% Membrane does not attract itself
			
			rep 		= repmat(r,2); 			% Repulsion between node-node, membrane-node and membrane-membrane
			
			dAsym 		= repmat(dA,2);			% The closest allowed is node on edge, or node on node. No crossing, but no hard core
			
			dSep 		= [dSN,dSNM;
				   	  	   dSNM,dSM]; 			% Nodes prefer to be 1unit apart so their drawn radii touch at preferred distance
				   			 					% Nodes and membrane are 0.5units apart so they touch, membrane and membrane 0.5units to stop overlap
			dLim 		= [dLN,dLNM;
				     	  dLNM,dLM]; 			% The limit where interactions are sought


			%---------------------------------------------------
			% Make the tumour cells
			%---------------------------------------------------

			% Radius gives the position of the nodes, we need to determine a
			% number of cells and a spacing so that each cell starts with
			% minimal compression

			% This is similar to finding an inscribed polygon with a given side length
			% but we aren't expecting it to close perfectly
			% The side length is the preferred separation between cells.

			nodeList = Node.empty();
			cellList = NodeCell.empty();

			dtheta  = 2 * asin(dSN/(2*radius));
			nCells = fix((2*pi)/dtheta);
			dtheta  = 2*pi/nCells; 

			for theta = 0:dtheta:(2*pi-dtheta)

				x = radius * cos(theta);
				y = radius * sin(theta);

				n = Node(x,y,obj.GetNextNodeId());
				ccm = NodeCellCycleSlowGrowth(t0, tg, f, obj.dt);
				c =  NodeCell(n, ccm, obj.GetNextCellId());

				% Needs a pointer to the simulation object so it can access the space partition
				% Also need the distances so it can accurate calculate the area
				cellArea = NodeCellArea(obj, dSN, dSNM);
				c.AddCellData(cellArea); 
				c.newCellTargetArea = pi*dSNM^2;

				nodeList(end+1) = n;
				cellList(end+1) = c;

			end


			%---------------------------------------------------
			% Make the cell that acts as the membrane
			%---------------------------------------------------

			centre = [0,0];
			nEdges = 40;

			[membrane, membraneNodes, membraneEdges] = obj.MakeCircularMembrane(centre, radius + dSNM, nEdges);

			obj.nodeList = [nodeList, membraneNodes];
			obj.elementList = membraneEdges;
			obj.cellList = [cellList, membrane];

			
			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% One force to keep the edges a certain length
			springFunction = @(n, l) mpe*(n - l);
			obj.AddElementBasedForce(EdgeSpringForce(springFunction));

			 % And another for all the interactions
			obj.AddNeighbourhoodBasedForce(CellTypeNodeCellForce(att, rep, dAsym, dSep, dLim, cellTypes, obj.dt, false));

			% THe pressure force applied to the internal cells.
			obj.AddTissueBasedForce(ConstantRadialPressure(dF, membrane, dSN/2));
			

			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------
			% Need the box size at least 1x1 due to the size of the cells'
			% interaction radius
			obj.boxes = SpacePartition(1, 1, obj);
			% obj.boxes.onlyBoxesInProximity = false;


			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------

			obj.pathName = sprintf('TumourInMembrane/rad%gt0%gtg%gmpe%gf%gr%gaN%gaNM%gaM%gdA%gdSN%gdSNM%gdSM%gdLN%gdLNM%gdLM%gdF%gnEdges%g_seed%g/',radius,t0,tg,mpe,f,r,aN,aNM,aM,dA,dSN,dSNM,dSM,dLN,dLNM,dLM,dF,nEdges, seed);

			obj.AddSimulationData(SpatialState());
			obj.AddDataWriter(WriteSpatialState(20,obj.pathName));


		end

		function [m, membraneNodes, membraneEdges] = MakeCircularMembrane(obj, centre, radius, nEdges)

			% The extent of the arc that makes the bag
			thetaStart = 0;
			thetaEnd = 2 * pi;

			nEdges = 40;

			dtheta = abs(thetaStart - thetaEnd)/nEdges;

			natLen = dtheta * radius;

			x = [];
			y = [];

			for theta = thetaStart:dtheta:(thetaEnd - dtheta)

				x(end+1) = radius * cos(theta);
				y(end+1) = radius * sin(theta);

			end

			membraneNodes = Node.empty();

			for i = 1:length(x)

				membraneNodes(end+1) = Node(x(i),y(i),obj.GetNextNodeId);

			end

			membraneEdges = Element.empty();

			for i = 1:length(membraneNodes)-1
				membraneEdges(end+1) = Element(membraneNodes(i), membraneNodes(i+1), obj.GetNextElementId());
				membraneEdges(end).naturalLength = natLen;
			end

			membraneEdges(end+1) = Element(membraneNodes(end), membraneNodes(1), obj.GetNextElementId());
			membraneEdges(end).naturalLength = natLen;


			% We now have a bag solely of edges, just need forces now

			m = Membrane(membraneNodes, membraneEdges, obj.GetNextCellId);

		end

		function RunToConfluence(obj, t)

			% This function runs the simulation until all cells are stopped
			% by contact inhibition. The input t is the maximum time to simulate
			% in case confluence is not reached

			obj.AddStoppingCondition(ConfluentStoppingCondition());

			obj.RunToTime(t);

		end
		
	end

end