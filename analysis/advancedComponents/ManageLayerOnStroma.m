classdef ManageLayerOnStroma < MatlabSimulation
	% Runs the CellGrowing simulation and handles all of the 
	% data processing and storage


	properties (SetAccess = immutable)
		% The name of the actual chaste test function as a string. This will
		% be used to build the simulation command and directory structure

		% Since this is a concrete implementation of a chasteSimulation the
		% name of the test will never be changed

		matlabTest = 'LayerOnStroma'

	end

	properties (SetAccess = private)
		% These are the input variables for CellGrowing
		% If new input variables are added, this may
		% need to be updated

		% Number of cells
		n 			double {mustBeNonnegative}

		% Cell cycle phase lengths
		p 			double {mustBeNonnegative}
		g 			double {mustBeNonnegative}

		f			double {mustBeNonnegative}
		b			double {mustBeNonnegative}


		sae			double {mustBeNonnegative}
		spe			double {mustBeNonnegative}

		% These are solver parameters
		t 			double {mustBeNonnegative}
		dt 	= 0.002

		% This is the RNG seed parameter
		rngSeed 	double {mustBeNumeric}

		outputLocation
	end

	properties

		buckledWiggleRatio = 2

	end

	methods
		function obj = ManageLayerOnStroma(n, p, g, b, f, sae, spe, seed)
			% The constructor for the runLayerOnStroma object
			% This expects the variables to be handed in as maps, which helps
			% make some of the generation functions easier and less cluttered to write
			% In addition, it needs to know where to find the 'Research' folder
			% so the functions can be used on multiple different machines
			% without needing to manually change
			% the path each time the script moves to another computer

			obj.n 		= n;
			obj.p 		= p;
			obj.g 		= g;
			obj.f 		= f;
			obj.b 		= b;
			obj.sae		= sae;
			obj.spe		= spe;
			obj.rngSeed = seed;

			

			obj.simObj = LayerOnStroma(n, p, g, b, f, sae, spe, seed);
			obj.simObj.dt = obj.dt;

			obj.outputTypes = {BottomWiggleData};

			obj.GenerateSaveLocation();

		end

	end


	methods (Access = protected)
		% Helper methods to build the class


		function GenerateSaveLocation(obj)
			% This generates the full path to the specific data file for the simulation
			% If the path doesn't exist it creates the missing folder structure

			obj.saveLocation = obj.simObj.simulationOutputLocation;

		end

		function SimulationCommand(obj)

			obj.simObj.RunToBuckle(obj.buckledWiggleRatio);

		end

	end

end








