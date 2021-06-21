classdef RestartDynamicCrypt < MatlabSimulation
	% Manages the running and data handling of the DynamicLayer simulation
	% for the various analyses around buckling


	properties (SetAccess = immutable)

		matlabTest = 'DynamicLayer'

	end

	properties (SetAccess = private)

		% Cell cycle phase lengths
		p 			double {mustBeNonnegative}
		g 			double {mustBeNonnegative}

		% growthTriggerFraction
		f			double {mustBeNonnegative}

		% Force parameters
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


	methods

		function obj = RestartDynamicCrypt(crypt, p, g, b, f, sae, spe, wnt)
			

			% Takes a saved DynamicCrypt simulation, and restarts it.
			% Input parameters can be changed that don't relate to the physical
			% shape of the supporting tissue

			load(crypt);

			% We can change:
			% p, the pause/resting phase duration
			% g, the growing phase duration
			% f, the contact inhibition fraction
			% ... for a given cell or all the cells
			% and for the stromal support, we can change
			% b, The interaction spring force parameter
			% sae, the stromal area energy factor
			% spe, the stroma perimeter energy factor
			% wnt = wntCutoff, the distance from the bottom of the crypt to the point where differentiation occurs

			% Other force related parameters may be changed, but aren't
			% specifically included yet

			%---------------------------------------------------
			% Add in the forces
			%---------------------------------------------------

			% Modify the stroma internal forces.
			d.cellBasedForces(2).areaEnergyParameter = sae;
			d.cellBasedForces(2).surfaceEnergyParameter = spe;
			d.cellBasedForces(2).edgeAdhesionParameter = 0;

			att = [0,b;
				   b,0]; % No attraction between epithelial cells
			% Modify the neighbourhood based force
			d.neighbourhoodBasedForces.springRateAttraction = att;
			d.neighbourhoodBasedForces.springRateRepulsion = repmat(b,2);
			%---------------------------------------------------
			% Add the data writers
			%---------------------------------------------------
			%  A bit hacky, but should work
			d.pathName = sprintf('RestartDynamicCrypt/%s_p%gg%gb%gsae%gspe%gf%g/',crypt,p,g,b,sae,spe,f);
			d.dataWriters = WriteSpatialState(100,d.pathName);

			obj.simObj = d;
			%---------------------------------------------------
			% All done. Ready to roll
			%---------------------------------------------------
			d.simulationOutputLocation = [getenv('EDGEDIR'),'/SimulationOutput/' d.pathName];

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

			obj.simObj.RunToTime(obj.simObj.t + 100);

		end

	end

end








