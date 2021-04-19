classdef OptimalCrypt < Analysis

	% This is for the optimal point analysis from the Chaste model
	% mainly used here to keep in the format and stop loose files floating around

	properties

		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT

		seed = 1:50;

		targetTime = 500;

		analysisName = 'OptimalCrypt';

		parameterSet = []
		missingParameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		

	end

	methods

		function obj = OptimalCrypt()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = false;

		end

		function MakeParameterSet(obj)

			params = [];

			obj.parameterSet = params;

		end

		

		function BuildSimulation(obj)

			% obj.MakeParameterSet();
			% obj.ProduceSimulationFiles();
			
		end

		function AssembleData(obj)

			% Load the specific file that contains the optimal points
			load([getenv('EDGEDIR'),'/analysis/penalties.mat']);

			% This loads the data that contains both the file name (hence the parameters)
			% and the output behaviour

			% It is stored in a cell vector. Each index specifies the crypt.
			% in each cell is a cell array containing the output values, and the file name
			% which contains the parameter values

			params = {[],[],[],[],[],[],[],[]};

			for i = 1:length(penalties)
				data = penalties{i};

				for j = 1:length(data)
					filename = data{j};

					t = split(filename{1},'_');
					% t =

					%   15×1 cell array

					%     {'params'}
					%     {'cct'   }
					%     {'11.564'}
					%     {'ees'   }
					%     {'230'   }
					%     {'ms'    }
					%     {'410'   }
					%     {'n'     }
					%     {'34.1'  }
					%     {'np'    }
					%     {'12.3'  }
					%     {'vf'    }
					%     {'0.656' }
					%     {'wt'    }
					%     {'8.1'   }
					t = [str2num(t{9}),str2num(t{11}),str2num(t{5}),str2num(t{7}),str2num(t{3}),str2num(t{15}),str2num(t{13})];
					params{i} = [params{i};t];

				end

			end

			obj.result = {params};
			

		end

		function PlotData(obj)

			params = obj.result{1};

			h = figure;

			i = 3;

			vals = params{i};

			paramNames = {'Sloughing height', 'Differentiation height', 'Cell interaction stiffness', 'Memebrane adhesion stiffness',...
							'Cell cycle duration', 'Growth duration', 'Contact inhibition fraction'};

			for j = 1:7
				for k = j+1:7
					for l = k+1:7

					h = figure;

					scatter3(vals(:,j),vals(:,k),vals(:,l));
					
					xlabel(paramNames{j},'Interpreter', 'latex', 'FontSize', 15);
					ylabel(paramNames{k},'Interpreter', 'latex', 'FontSize', 15);
					zlabel(paramNames{l},'Interpreter', 'latex', 'FontSize', 15);
					title('Parameters for optimal crypts','Interpreter', 'latex', 'FontSize', 22);
					
					x_r = max(vals(:,j)) - min(vals(:,j));
					y_r = max(vals(:,k)) - min(vals(:,k));
					z_r = max(vals(:,l)) - min(vals(:,l));
					
					xlim([min(vals(:,j))-x_r*0.1, max(vals(:,j))+x_r*0.1]);
					ylim([min(vals(:,k))-y_r*0.1, max(vals(:,k))+y_r*0.1]);
					zlim([min(vals(:,l))-z_r*0.1, max(vals(:,l))+z_r*0.1]);

					end

				end

			end

			% SavePlot(obj, h, sprintf(''));



		end

	end

end