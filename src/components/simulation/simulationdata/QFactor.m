classdef QFactor < AbstractSimulationData
	% Calculates the QFactor for a Ring Simulation

	properties 

		name = 'QFactor'
		data = []

	end

	methods

		function obj = QFactor
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			edges = t.elementList;
			angles = zeros(size(edges));
			% To calculate the QFactor, we need to find the angle
			% of every single edge
			for i = 1:length(edges)

				n1 = edges(i).Node1;
				n2 = edges(i).Node2;

				rise = n2.y - n1.y;
				rrun = n2.x - n1.x;

				angles(i) = atan( rise / rrun ); 

			end

			obj.data = sqrt(  mean(cos( 2.* angles))^2 + mean(sin( 2.* angles))^2   );

		end
		
	end


end