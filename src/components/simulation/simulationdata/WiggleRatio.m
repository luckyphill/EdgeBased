classdef WiggleRatio < AbstractSimulationData
	% Calculates the wiggle ratio

	properties 

		name = 'wiggleRatio'
		data = 1;

	end

	methods

		function obj = WiggleRatio
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			sd = t.simData('centreLine');
			cl = sd.GetData(t);

			l = 0;

			for i = 1:length(cl)-1
				l = l + norm(cl(i,:) - cl(i+1,:));
			end

			w = cl(end,1) - cl(1,1);

			obj.data = l / w;

		end
		
	end


end