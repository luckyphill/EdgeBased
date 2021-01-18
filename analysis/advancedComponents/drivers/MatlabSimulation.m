classdef MatlabSimulation < SimulationDriver
	% A class defining the generic things a simulation needs
	% It will be handed an object of type simulation
	% The simulation runner doesn't care what happens to get the data,
	% it just activates the functions that generate it or retreive it
	% To that end, it doesn't care about variables, generating file names etc,
	% it just uses what the simulation has defined


	properties (Abstract, SetAccess = immutable)
		% The name of the actual test function as a string. This will
		% be used to build the simulation command and directory structure
		% This must be set in a subclass

		matlabTest char

	end

	properties (SetAccess = protected)
		% These properties are essential for the method "runSimulation" to function


		% The folder where the processed output will be saved
		saveLocation char

		% The simulation object
		simObj

	end


	properties (SetAccess = protected)
		% These are a list of maps for the parameters.
		% They are broken up by types that will be typically used
		% They don't have to be used, and it is probably more convenient
		% in most instances just to explicitly write the parameters out
		% as properties in subclasses. They are left here just in case

		% The parameters of the simulation describing the cell behaviour
		simParams containers.Map

		% Parameters fed into the solver, usually time and time step
		solverParams containers.Map 

		% The rng seed that defines the starting configuration
		seedParams containers.Map 

		% The path to the directory containing the Research directory
		researchPath

		% The text from any error that gets tripped during a simulation
		% that causes it to fail.
		errorText

		% The absolute path to the error file
		errorFile char

	end

	methods (Abstract, Access = protected)
		% These must be implemented in a concrete subclass

		% Sets the folder where processed data will be saved
		GenerateSaveLocation

		% The command that runs the simulation
		SimulationCommand


	end

	methods

		function successCode = RunSimulation(obj)
			% Runs the simulation command
			% This will never throw an error

			% The 'system' command will always work in Matlab. It doesn't care what you type
			% it just reports back what the console said
			obj.errorFile = [obj.saveLocation,'output.err'];
			
			fprintf('Running %s with input parameters:\n', obj.matlabTest);
			% Delete the previous error file
			[~,~] = system(['rm ', obj.errorFile]);

			successCode = 0;
			try

				obj.SimulationCommand();
				for i = 1:length(obj.outputTypesToRun)
					obj.outputTypesToRun{i}.saveData(obj);
				end
				successCode = 1;
			
			catch EM
				% The simulation ended in an unexpected way, save console output to the error file
				fid = fopen(obj.errorFile,'w');
				fprintf(fid, EM.message);
				fclose(fid);
				fprintf('Problem running simulation. Error message saved in:\n%s', obj.errorFile);
			end
			
			% If failed returns 0, then the command completed without failing
			% However, this does not mean the data will necessarily be in the correct
			% format. Error checking needs to happen in the data processing
			% Data should be able to be processed correctly

		end

	end


end