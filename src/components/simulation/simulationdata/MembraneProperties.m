classdef MembraneProperties < AbstractSimulationData
	% Calculates the membrane properties

	properties 

		name = 'membraneProperties'
		data = []

	end

	methods

		function obj = MembraneProperties
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			% Get the properties of the membrane.
			% Only useful for simulations that have a single ring membrane
			% for instance TumourInMembrane
			m = Membrane.empty();
			for i = 1:length(t.cellList)
				c = t.cellList(i);
				if isa(c, 'Membrane')
					m = c;
					break;
				end
			end

			if isempty(m)
				error('MP:NoMembrane','Simlation does not contain a Membrane object')
			end

			perimeter = 0;
			for i = 1:length(m.elementList)
				e = m.elementList(i);
				perimeter = perimeter + e.GetLength();
			end

			nPos = reshape([m.nodeList.position],2,[])';
			centre = mean(nPos);

			
			avgRadius = mean(sqrt(sum((nPos - centre).^2,2)));

			x = [m.nodeList.x];
			y = [m.nodeList.y];
			
			intArea = polyarea(x,y);

			obj.data = [intArea, perimeter, avgRadius];

		end
		
	end


end