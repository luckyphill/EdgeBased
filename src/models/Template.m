classdef SimulationName < AbstractCellSimulation

	% A template for constructing simulations

	properties

		dt = 0.001
		t = 0
		eta = 1

		timeLimit = 1000

		pathName
		simulationOutputLocation

	end

	methods

		function obj = SimulationName(p1, p2, p3, seed)
			
			obj.SetRNGSeed(seed);

			% p1, description
			% p2, description
			% p3, description

			% Internal variables
			v1 = 1;
			v2 = 2;
			v3 = 3;

			%---------------------------------------------------
			% Make cells that will populate the crypt
			%---------------------------------------------------

			% Make nodes
			nodeList = Node.empty();
			% Make edges
			elementList = Element.empty();
			% Make cells
			cellList = AbstractCell.empty();
			
			obj.AddNodesToList( nodeList );
			obj.AddElementsToList( elementList );
			obj.cellList = cellList;


			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			obj.AddElementBasedForce(); % Adds force based on the state of the edge
			obj.AddCellBasedForce(); % Adds force based on the state of the cell
			obj.AddNeighbourhoodBasedForce(); % Adds force based on neighbourhood interactions. Requires a space partition
			obj.AddTissueBasedForce(); % Adds force based on the state of the whole tissue
			
			%---------------------------------------------------
			% Add space partition
			%---------------------------------------------------

			obj.boxes = SpacePartition(0.5, 0.5, obj);

			%---------------------------------------------------
			% Add the data we'd like to store
			%---------------------------------------------------

			obj.AddSimulationData(SpatialState());


			%---------------------------------------------------
			% Add modfiers
			%---------------------------------------------------
			
			obj.AddSimulationModifier();

			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------
			
			obj.pathName = sprintf('SimulationName/p1%gp2%gp3%gv1%gv2%gv3_seed%d/',p1,p2,p3,v1,v2,v3, seed);
			obj.AddDataWriter(WriteSpatialState(100,obj.pathName));

			% A little hack to make the parameter sweeps slightly easier to handle
			obj.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' obj.pathName];

			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------

			

		end

		function [output] = HelperFunction(obj, input)

			output = 1;

		end

	end

end
